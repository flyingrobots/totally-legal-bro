#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Report command: Generate detailed compliance report

# Shared dependency helpers
source "${LIB_DIR}/deps.sh"

function cmd_report() {
    echo -e "${BLUE}📊 Legal Compliance Report${NC}"
    echo "========================================"
    echo ""

    if ! validate_config; then
        exit 1
    fi

    local required_license
    local owner_name
    local dep_policy

    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")
    dep_policy=$(get_dependency_policy)

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
    echo -e "${BLUE}Compliance Status${NC}"
    echo ""

    local lic_json notice_json readme_json headers_json deps_json
    lic_json=$(license_status "${required_license}")
    notice_json=$(notice_status)
    readme_json=$(readme_status "${required_license}")
    headers_json=$(headers_status "${required_license}" "${owner_name}")
    deps_json=$(scan_dependencies)

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
            if [[ "${status}" == "fail" || "${status}" == "warn" ]]; then
                : $((CHECK_FAILURES++))
            fi
        done
    else
        report_status "LICENSE" "${lic_json}"
        report_status "NOTICE" "${notice_json}"
        report_status "README" "${readme_json}"
        report_headers "${headers_json}"
        report_deps "${deps_json}"
    fi

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

function report_status() {
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
    elif [[ "${status}" == "skip" ]]; then
        color="${YELLOW}SKIP${NC}"
    fi

    echo "${label}: ${color}"
    echo "  ${detail}"
}

function report_headers() {
    local json="$1"
    local status missing total
    status=$(echo "${json}" | jq -r '.status')
    missing=$(echo "${json}" | jq -r '.missing')
    total=$(echo "${json}" | jq -r '.total')

    local color="${GREEN}PASS${NC}"
    if [[ "${status}" == "fail" ]]; then
        color="${RED}FAIL${NC}"
        : $((CHECK_FAILURES++))
    fi

    echo "Headers: ${color}"
    echo "  ${total} files checked"
    if [[ ${missing} -gt 0 ]]; then
        echo "  Missing: ${missing}"
        echo "  Files:"
        echo "${json}" | jq -r '.files[] | "    - " + .'
    else
        echo "  All headers present"
    fi
}

function report_deps() {
    local json="$1"
    local status
    status=$(echo "${json}" | jq -r '.status')
    local color="${GREEN}PASS${NC}"
    if [[ "${status}" == "fail" ]]; then
        color="${RED}FAIL${NC}"
        : $((CHECK_FAILURES++))
    elif [[ "${status}" == "warn" ]]; then
        color="${YELLOW}WARN${NC}"
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
