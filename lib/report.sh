#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Report command: Generate detailed compliance report

function cmd_report() {
    echo -e "${BLUE}📊 Legal Compliance Report${NC}"
    echo "========================================"
    echo ""

    # Validate config exists
    if ! validate_config; then
        exit 1
    fi

    local required_license
    local owner_name
    local dep_policy

    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")
    dep_policy=$(get_dependency_policy)

    # Configuration Summary
    echo -e "${BLUE}Configuration${NC}"
    echo "  Required License: ${required_license}"
    echo "  Owner Name: ${owner_name}"

    if [[ -n "${dep_policy}" ]]; then
        echo "  Dependency Policy:"
        while IFS= read -r license; do
            echo "    - ${license}"
        done <<< "${dep_policy}"
    else
        echo "  Dependency Policy: None (all licenses allowed)"
    fi

    echo ""
    echo "========================================"
    echo ""

    # Re-run checks but capture output
    local status=0

    # Temporarily redirect to capture check results
    echo -e "${BLUE}Compliance Status${NC}"
    echo ""

    report_license_file "${required_license}"
    report_notice_file
    report_readme_license "${required_license}"
    report_source_headers "${required_license}" "${owner_name}"
    report_dependencies

    echo ""
    echo "========================================"
    echo ""

    if [[ ${CHECK_FAILURES} -eq 0 ]]; then
        echo -e "${GREEN}✓ Overall Status: COMPLIANT${NC}"
        echo ""
        echo "All checks passed. Your repo is legally chill! 🤙"
    else
        echo -e "${RED}✗ Overall Status: NON-COMPLIANT${NC}"
        echo ""
        echo "Found ${CHECK_FAILURES} issue(s). Run 'totally-legal-bro fix' to auto-fix."
    fi
}

function report_license_file() {
    local required_license="$1"

    echo -n "LICENSE file: "

    if [[ ! -f "LICENSE" ]]; then
        echo -e "${RED}MISSING${NC}"
        echo "  Action: Run 'totally-legal-bro fix' to create"
        : $((CHECK_FAILURES++))
        return
    fi

    # Check if LICENSE contains the license (flexible matching like check.sh)
    local license_base=$(echo "${required_license}" | sed 's/-.*//; s/\..*//')

    if ! grep -qi "${license_base}" LICENSE; then
        echo -e "${RED}INVALID${NC}"
        echo "  Expected: ${required_license}"
        echo "  Action: Manually update LICENSE file"
        : $((CHECK_FAILURES++))
        return
    fi

    echo -e "${GREEN}VALID${NC}"
    echo "  Contains: ${required_license}"
}

function report_notice_file() {
    echo -n "NOTICE file: "

    if [[ ! -f "NOTICE" ]]; then
        echo -e "${YELLOW}MISSING (optional)${NC}"
        echo "  Action: Run 'totally-legal-bro fix' to create boilerplate"
        return
    fi

    echo -e "${GREEN}PRESENT${NC}"
}

function report_readme_license() {
    local required_license="$1"

    echo -n "README.md license section: "

    if [[ ! -f "README.md" ]]; then
        echo -e "${RED}README MISSING${NC}"
        echo "  Action: Run 'totally-legal-bro fix' to create"
        : $((CHECK_FAILURES++))
        return
    fi

    if ! grep -qi "license" README.md || ! grep -q "${required_license}" README.md; then
        echo -e "${YELLOW}INCOMPLETE${NC}"
        echo "  Action: Run 'totally-legal-bro fix' to append license section"
        : $((CHECK_FAILURES++))
        return
    fi

    echo -e "${GREEN}PRESENT${NC}"
}

function report_source_headers() {
    local required_license="$1"
    local owner_name="$2"

    echo "Source file headers:"

    # Get all tracked source files (exclude data/config files like JSON, TOML, YAML, XML)
    local files
    files=$(git ls-files | grep -E '\.(sh|bash|py|js|ts|tsx|jsx|go|rs|c|cpp|h|hpp|java|rb|php|tex)$' | grep -v -E '\.(json|toml|yaml|yml|xml|md|txt)$' || true)

    if [[ -z "${files}" ]]; then
        echo "  No source files found"
        return
    fi

    local total=0
    local valid=0
    local missing=0
    declare -a missing_files=()

    while IFS= read -r file; do
        : $((total++))

        local header
        header=$(head -n 20 "${file}")

        local has_spdx=false
        local has_copyright=false

        if echo "${header}" | grep -q "SPDX-License-Identifier:.*${required_license}"; then
            has_spdx=true
        fi

        if echo "${header}" | grep -E -q "Copyright.*(©|\(c\)).*${owner_name}"; then
            has_copyright=true
        fi

        if [[ "${has_spdx}" == true ]] && [[ "${has_copyright}" == true ]]; then
            : $((valid++))
        else
            : $((missing++))
            missing_files+=("${file}")
        fi
    done <<< "${files}"

    echo "  Total files: ${total}"
    echo -e "  Valid headers: ${GREEN}${valid}${NC}"

    if [[ ${missing} -gt 0 ]]; then
        echo -e "  Missing headers: ${RED}${missing}${NC}"
        echo ""
        echo "  Files needing headers:"
        for file in "${missing_files[@]}"; do
            echo "    - ${file}"
        done
        echo ""
        echo "  Action: Run 'totally-legal-bro fix' to inject headers"
        : $((CHECK_FAILURES++))
    fi
}

function report_dependencies() {
    echo "Dependency licenses:"

    # Check for common manifest files
    local manifests=()

    [[ -f "package.json" ]] && manifests+=("package.json:npm")
    [[ -f "requirements.txt" ]] && manifests+=("requirements.txt:pip")
    [[ -f "Cargo.toml" ]] && manifests+=("Cargo.toml:cargo")
    [[ -f "go.mod" ]] && manifests+=("go.mod:go")

    if [[ ${#manifests[@]} -eq 0 ]]; then
        echo "  No dependency manifests found"
        return
    fi

    local has_policy
    has_policy=$(get_dependency_policy)

    if [[ -z "${has_policy}" ]]; then
        echo "  No policy defined - all licenses allowed"
        return
    fi

    echo "  Allowed licenses:"
    while IFS= read -r license; do
        echo "    - ${license}"
    done <<< "${has_policy}"

    echo ""
    echo "  Manifests found:"
    for manifest_info in "${manifests[@]}"; do
        local manifest="${manifest_info%%:*}"
        echo "    - ${manifest}"
    done

    echo ""
    echo -e "  ${YELLOW}Note: Automatic dependency scanning requires additional tooling${NC}"
    echo "    Recommend: npx license-checker (for npm)"
}
