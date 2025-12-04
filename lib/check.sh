#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Check command: Validate LICENSE, headers, and dependencies

# Shared dependency scanning helpers
source "${LIB_DIR}/deps.sh"
source "${LIB_DIR}/utils.sh"

# Global state for tracking failures
declare -i CHECK_FAILURES=0
: "${GIT_CMD:=git}"

function license_status() {
    local required_license="$1"

    if [[ ! -f "LICENSE" ]]; then
        jq -n --arg status "fail" --arg detail "LICENSE file not found" '{status:$status, detail:$detail}'
        return
    fi

    local license_base
    license_base=$(echo "${required_license}" | sed 's/-.*//; s/\..*//')

    if ! grep -qi "${license_base}" LICENSE; then
        jq -n --arg status "fail" --arg detail "LICENSE file does not contain '${required_license}'" '{status:$status, detail:$detail}'
        return
    fi

    # Placeholder detection
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
            jq -n --arg status "fail" --arg detail "LICENSE contains placeholder text (${pattern})" '{status:$status, detail:$detail}'
            return
        fi
    done

    jq -n '{status:"pass", detail:"LICENSE file present"}'
}

function notice_status() {
    if [[ ! -f "NOTICE" ]]; then
        jq -n '{status:"warn", detail:"NOTICE file not found (optional)"}'
    else
        jq -n '{status:"pass", detail:"NOTICE present"}'
    fi
}

function readme_status() {
    local required_license="$1"

    if [[ ! -f "README.md" ]]; then
        jq -n '{status:"fail", detail:"README.md not found"}'
        return
    fi

    if ! grep -qi "license" README.md || ! grep -qi "${required_license}" README.md; then
        jq -n --arg status "fail" --arg detail "README.md should mention the license (${required_license})" '{status:$status, detail:$detail}'
        return
    fi

    jq -n '{status:"pass", detail:"README license section present"}'
}

function headers_status() {
    local required_license="$1"
    local owner_name="$2"

    local files
    files=$(get_source_files)

    if [[ -z "${files}" ]]; then
        jq -n '{status:"pass", detail:"No source files found", total:0, missing:0, files:[]}'
        return
    fi

    local total=0
    local missing=0
    local missing_files=()

    while IFS= read -r file; do
        : $((total++))
        local header
        header=$(head -n 20 "${file}")

        local has_spdx=false
        local has_copyright=false

        if echo "${header}" | grep -E -q "SPDX-License-Identifier:.*${required_license}"; then
            has_spdx=true
        fi

        if echo "${header}" | grep -E -q "Copyright.*(©|\(c\)).*${owner_name}"; then
            has_copyright=true
        fi

        if [[ "${has_spdx}" == false ]] || [[ "${has_copyright}" == false ]]; then
            missing_files+=("${file}")
            : $((missing++))
        fi
    done <<< "${files}"

    local status="pass"
    if [[ ${missing} -gt 0 ]]; then
        status="fail"
    fi

    local detail_msg="${missing}/${total} files missing headers"
    if [[ ${missing} -gt 0 ]]; then
        detail_msg="${detail_msg}; missing proper headers"
    fi

    jq -n \
        --arg status "${status}" \
        --arg detail "${detail_msg}" \
        --argjson total ${total} \
        --argjson missing ${missing} \
        --argjson files "$(printf '%s\n' "${missing_files[@]}" | jq -R . | jq -s .)" \
        '{status:$status, detail:$detail, total:$total, missing:$missing, files:$files}'
}

function cmd_check() {
    if [[ "${OUTPUT_JSON}" -eq 0 ]]; then
        echo -e "${BLUE}🔍 Running legal compliance checks...${NC}"
        echo ""
    fi

    local manifest_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --manifests)
                manifest_override="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Validate config exists
    if ! validate_config "${CONFIG_FILE}"; then
        exit 1
    fi

    local required_license
    local owner_name

    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")
    if [[ "${OUTPUT_JSON}" -eq 0 ]]; then
        echo "Config: License=${required_license}, Owner=${owner_name}"
        echo ""
    fi

    local lic_json notice_json readme_json headers_json deps_json

    lic_json=$(license_status "${required_license}")
    notice_json=$(notice_status)
    readme_json=$(readme_status "${required_license}")
    headers_json=$(headers_status "${required_license}" "${owner_name}")
    deps_json=$(scan_dependencies "${manifest_override}")

    if [[ "${OUTPUT_JSON}" -eq 1 ]]; then
        jq -n \
            --argjson license "${lic_json}" \
            --argjson notice "${notice_json}" \
            --argjson readme "${readme_json}" \
            --argjson headers "${headers_json}" \
            --argjson dependencies "${deps_json}" \
            '{license:$license, notice:$notice, readme:$readme, headers:$headers, dependencies:$dependencies}'
        for s in "${lic_json}" "${notice_json}" "${readme_json}" "${headers_json}" "${deps_json}"; do
            status=$(echo "${s}" | jq -r '.status')
            if [[ "${status}" == "fail" ]]; then
                : $((CHECK_FAILURES++))
            elif [[ "${status}" == "warn" ]]; then
                : $((CHECK_FAILURES++))
            fi
        done
    else
        render_status "LICENSE" "${lic_json}"
        render_status "NOTICE" "${notice_json}"
        render_status "README" "${readme_json}"
        render_headers_status "${headers_json}"
        render_deps_status "${deps_json}"
    fi

    if [[ "${OUTPUT_JSON}" -eq 0 ]]; then
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
    else
        # JSON mode: exit code reflects failures
        [[ ${CHECK_FAILURES} -eq 0 ]] && exit 0 || exit 1
    fi
}

function render_status() {
    local label="$1"
    local json="$2"
    local status detail
    status=$(echo "${json}" | jq -r '.status')
    detail=$(echo "${json}" | jq -r '.detail')

    local color="${GREEN}PASS${NC}"
    if [[ "${status}" == "fail" ]]; then
        color="${RED}FAIL${NC}"
        : $((CHECK_FAILURES++))
    elif [[ "${status}" == "warn" ]]; then
        color="${YELLOW}WARN${NC}"
    fi

    echo "${label}: ${color} - ${detail}"
}

function render_headers_status() {
    local json="$1"
    local status detail missing
    status=$(echo "${json}" | jq -r '.status')
    detail=$(echo "${json}" | jq -r '.detail')
    missing=$(echo "${json}" | jq -r '.missing')

    local color="${GREEN}PASS${NC}"
    if [[ "${status}" == "fail" ]]; then
        color="${RED}FAIL${NC}"
        : $((CHECK_FAILURES++))
    fi

    echo "Headers: ${color} - ${detail}"
    if [[ ${missing} -gt 0 ]]; then
        echo "  Files missing headers:"
        echo "${json}" | jq -r '.files[]' | sed 's/^/    → /'
    fi
}

function render_deps_status() {
    local json="$1"
    local status
    status=$(echo "${json}" | jq -r '.status')
    local color="${GREEN}PASS${NC}"
    if [[ "${status}" == "fail" ]]; then
        color="${RED}FAIL${NC}"
        : $((CHECK_FAILURES++))
    elif [[ "${status}" == "warn" ]]; then
        color="${YELLOW}WARN${NC}"
        : $((CHECK_FAILURES++))
    elif [[ "${status}" == "skip" ]]; then
        color="${YELLOW}SKIP${NC}"
    fi

    echo "Dependencies: ${color}"
    echo "${json}" | jq -r '.notes[]? | "  • " + .' 
    if [[ "${status}" == "fail" ]]; then
        echo "  Violations:"
        echo "${json}" | jq -r '.violations[] | "    - " + .'
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
    if [[ ! -d "node_modules" ]]; then
        echo -e "    ${YELLOW}SKIP${NC}: node_modules not found (run npm install first)"
        return
    fi

    # Placeholder message now removed; npm scanning handled in deps.sh
    echo -e "    ${YELLOW}INFO${NC}: npm scanning handled by deps.sh"
}
