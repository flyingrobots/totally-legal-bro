#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Check command: Validate LICENSE, headers, and dependencies

# Global state for tracking failures
declare -i CHECK_FAILURES=0
declare -a MISSING_HEADERS=()
declare -a LICENSE_VIOLATIONS=()

function cmd_check() {
    echo -e "${BLUE}🔍 Running legal compliance checks...${NC}"
    echo ""

    # Validate config exists
    if ! validate_config; then
        exit 1
    fi

    local required_license
    local owner_name

    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")

    echo "Config: License=${required_license}, Owner=${owner_name}"
    echo ""

    # Run all checks
    check_license_file "${required_license}"
    check_notice_file
    check_readme_license "${required_license}"
    check_source_headers "${required_license}" "${owner_name}"
    check_dependencies

    echo ""
    if [[ ${CHECK_FAILURES} -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ ${CHECK_FAILURES} check(s) failed${NC}"
        echo ""
        echo "Run 'totally-legal-bro fix' to auto-fix common issues"
        exit 1
    fi
}

function check_license_file() {
    local required_license="$1"

    echo -n "Checking LICENSE file... "

    if [[ ! -f "LICENSE" ]]; then
        echo -e "${RED}FAIL${NC}"
        echo "  → LICENSE file not found"
        : $((CHECK_FAILURES++))
        return
    fi

    # Check if LICENSE contains the SPDX identifier (case-insensitive, flexible matching)
    # For "Apache-2.0" match "Apache", for "MIT" match "MIT", etc.
    local license_pattern="${required_license}"
    # Extract base name (e.g., "Apache-2.0" -> "Apache", "BSD-3-Clause" -> "BSD")
    local license_base=$(echo "${required_license}" | sed 's/-.*//; s/\..*//')

    if ! grep -qi "${license_base}" LICENSE; then
        echo -e "${RED}FAIL${NC}"
        echo "  → LICENSE file does not contain '${required_license}' (looking for '${license_base}')"
        : $((CHECK_FAILURES++))
        return
    fi

    # Check for placeholder/bogus text that indicates an incomplete license
    local placeholder_patterns=(
        '\[Full.*text.*here\]'
        '\[.*license.*text.*\]'
        'TODO'
        'PLACEHOLDER'
        '\[yyyy\]'
        '\[name of copyright owner\]'
        '\[fullname\]'
    )

    for pattern in "${placeholder_patterns[@]}"; do
        if grep -qiE "${pattern}" LICENSE; then
            echo -e "${RED}FAIL${NC}"
            echo "  → LICENSE contains placeholder text: ${pattern}"
            echo "  → Please replace with complete license text"
            : $((CHECK_FAILURES++))
            return
        fi
    done

    echo -e "${GREEN}PASS${NC}"
}

function check_notice_file() {
    echo -n "Checking NOTICE file... "

    if [[ ! -f "NOTICE" ]]; then
        echo -e "${YELLOW}WARN${NC}"
        echo "  → NOTICE file not found (optional but recommended)"
        return
    fi

    echo -e "${GREEN}PASS${NC}"
}

function check_readme_license() {
    local required_license="$1"

    echo -n "Checking README.md license section... "

    if [[ ! -f "README.md" ]]; then
        echo -e "${RED}FAIL${NC}"
        echo "  → README.md not found"
        : $((CHECK_FAILURES++))
        return
    fi

    # Look for license mention (case-insensitive)
    if ! grep -qi "license" README.md || ! grep -q "${required_license}" README.md; then
        echo -e "${YELLOW}WARN${NC}"
        echo "  → README.md should mention the license: ${required_license}"
        : $((CHECK_FAILURES++))
        return
    fi

    echo -e "${GREEN}PASS${NC}"
}

function check_source_headers() {
    local required_license="$1"
    local owner_name="$2"

    echo "Checking source file headers..."

    # Get all tracked source files (exclude data/config files like JSON, TOML, YAML, XML)
    local files
    files=$(git ls-files | grep -E '\.(sh|bash|py|js|ts|tsx|jsx|go|rs|c|cpp|h|hpp|java|rb|php|tex)$' | grep -v -E '\.(json|toml|yaml|yml|xml|md|txt)$' || true)

    if [[ -z "${files}" ]]; then
        echo "  No source files found to check"
        return
    fi

    local total=0
    local missing=0

    while IFS= read -r file; do
        : $((total++))

        # Read first 20 lines
        local header
        header=$(head -n 20 "${file}")

        # Check for SPDX identifier
        local has_spdx=false
        local has_copyright=false

        if echo "${header}" | grep -q "SPDX-License-Identifier:.*${required_license}"; then
            has_spdx=true
        fi

        if echo "${header}" | grep -E -q "Copyright.*(©|\(c\)).*${owner_name}"; then
            has_copyright=true
        fi

        if [[ "${has_spdx}" == false ]] || [[ "${has_copyright}" == false ]]; then
            MISSING_HEADERS+=("${file}")
            : $((missing++))
        fi
    done <<< "${files}"

    if [[ ${missing} -gt 0 ]]; then
        echo -e "  ${RED}FAIL${NC}: ${missing}/${total} files missing proper headers"
        for file in "${MISSING_HEADERS[@]}"; do
            echo "    → ${file}"
        done
        : $((CHECK_FAILURES++))
    else
        echo -e "  ${GREEN}PASS${NC}: All ${total} source files have proper headers"
    fi
}

function check_dependencies() {
    echo "Checking dependency licenses..."

    # Check for common manifest files
    local manifests=()

    [[ -f "package.json" ]] && manifests+=("package.json:npm")
    [[ -f "requirements.txt" ]] && manifests+=("requirements.txt:pip")
    [[ -f "Cargo.toml" ]] && manifests+=("Cargo.toml:cargo")
    [[ -f "go.mod" ]] && manifests+=("go.mod:go")

    if [[ ${#manifests[@]} -eq 0 ]]; then
        echo "  No dependency manifests found, skipping"
        return
    fi

    local has_policy
    has_policy=$(get_dependency_policy)

    if [[ -z "${has_policy}" ]]; then
        echo -e "  ${YELLOW}SKIP${NC}: No dependencyPolicy defined in config"
        return
    fi

    # For each manifest, try to extract dependency licenses
    for manifest_info in "${manifests[@]}"; do
        local manifest="${manifest_info%%:*}"
        local pm="${manifest_info##*:}"

        echo "  Checking ${manifest} (${pm})..."

        case "${pm}" in
            npm)
                check_npm_licenses
                ;;
            pip|cargo|go)
                echo -e "    ${YELLOW}TODO${NC}: ${pm} license checking not yet implemented"
                ;;
        esac
    done
}

function check_npm_licenses() {
    # This is a simplified check - in reality you'd use `license-checker` or similar
    # For now, we'll just check if node_modules exists

    if [[ ! -d "node_modules" ]]; then
        echo -e "    ${YELLOW}SKIP${NC}: node_modules not found (run npm install first)"
        return
    fi

    # Basic check: look for common license files in dependencies
    # This is a placeholder for more sophisticated license scanning
    echo -e "    ${YELLOW}INFO${NC}: npm license scanning requires additional tooling"
    echo "      Recommend: npx license-checker --summary"
}
