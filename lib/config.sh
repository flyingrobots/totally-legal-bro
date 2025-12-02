#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Config parser and validator for .legalbro.json

CONFIG_FILE=".legalbro.json"

# Check if jq is available
function require_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed${NC}" >&2
        echo "Install it with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
        exit 1
    fi
}

# Check if config file exists
function config_exists() {
    [[ -f "${CONFIG_FILE}" ]]
}

# Validate config has required fields
function validate_config() {
    local config_file="${1:-${CONFIG_FILE}}"

    if [[ ! -f "${config_file}" ]]; then
        echo -e "${RED}Error: Config file not found: ${config_file}${NC}" >&2
        echo "Run 'totally-legal-bro init' to create one" >&2
        return 1
    fi

    require_jq

    # Check JSON is valid
    if ! jq empty "${config_file}" 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON in ${config_file}${NC}" >&2
        return 1
    fi

    # Check required fields
    local required_license
    local owner_name

    required_license=$(jq -r '.requiredLicense // empty' "${config_file}")
    owner_name=$(jq -r '.ownerName // empty' "${config_file}")

    if [[ -z "${required_license}" ]]; then
        echo -e "${RED}Error: Missing required field 'requiredLicense' in ${config_file}${NC}" >&2
        return 1
    fi

    if [[ -z "${owner_name}" ]]; then
        echo -e "${RED}Error: Missing required field 'ownerName' in ${config_file}${NC}" >&2
        return 1
    fi

    return 0
}

# Get a config value
function get_config() {
    local key="$1"
    local default="${2:-}"

    require_jq

    if ! config_exists; then
        echo "${default}"
        return
    fi

    local value
    value=$(jq -r ".${key} // empty" "${CONFIG_FILE}" 2>/dev/null || echo "")

    if [[ -z "${value}" ]]; then
        echo "${default}"
    else
        echo "${value}"
    fi
}

# Get dependency policy as array
function get_dependency_policy() {
    require_jq

    if ! config_exists; then
        return
    fi

    jq -r '.dependencyPolicy[]? // empty' "${CONFIG_FILE}" 2>/dev/null || true
}

# Check if a license is in the dependency policy
function is_license_allowed() {
    local license="$1"
    local policy

    policy=$(get_dependency_policy)

    # If no policy defined, allow everything
    if [[ -z "${policy}" ]]; then
        return 0
    fi

    # Check if license is in the policy
    while IFS= read -r allowed; do
        if [[ "${license}" == "${allowed}" ]]; then
            return 0
        fi
    done <<< "${policy}"

    return 1
}
