#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# BATS test helper functions

# Set up a clean test repo
setup_test_repo() {
    local repo_dir="${BATS_TEST_TMPDIR}/test-repo"

    # Clean up if exists
    rm -rf "${repo_dir}"

    # Create fresh repo
    mkdir -p "${repo_dir}"
    cd "${repo_dir}"
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"

    echo "${repo_dir}"
}

# Create a sample source file
create_source_file() {
    local file="$1"
    local content="${2:-// Sample code}"

    mkdir -p "$(dirname "${file}")"
    echo "${content}" > "${file}"
    git add "${file}"
}

# Create a config file
create_config() {
    local license="${1:-MIT}"
    local owner="${2:-Test Owner}"

    cat > .legalbro.json <<EOF
{
  "requiredLicense": "${license}",
  "ownerName": "${owner}",
  "dependencyPolicy": ["MIT", "Apache-2.0"]
}
EOF
    git add .legalbro.json
}

# Check if output contains a string
assert_output_contains() {
    local expected="$1"
    if [[ "${output}" != *"${expected}"* ]]; then
        echo "Expected output to contain: ${expected}"
        echo "Actual output: ${output}"
        return 1
    fi
}

# Check if output does not contain a string
assert_output_not_contains() {
    local unexpected="$1"
    if [[ "${output}" == *"${unexpected}"* ]]; then
        echo "Expected output NOT to contain: ${unexpected}"
        echo "Actual output: ${output}"
        return 1
    fi
}

# Run totally-legal-bro command
run_tlb() {
    run totally-legal-bro "$@"
}

# Create a nested node_modules structure
create_nested_npm_deps() {
    local num_deps="${1:-5}" # Number of dependencies to create
    local num_levels="${2:-3}" # Depth of nesting

    mkdir -p node_modules

    for ((i=0; i<num_deps; i++)); do
        local current_dir="node_modules"
        local license="MIT"
        # Make every 3rd dependency use GPL-3.0 to test violations
        if (( i % 3 == 0 )); then
            license="GPL-3.0"
        fi

        for ((j=0; j<num_levels; j++)); do
            local pkg_name="pkg-$i-level-$j"
            local pkg_path="${current_dir}/${pkg_name}"
            mkdir -p "${pkg_path}"
            cat > "${pkg_path}/package.json" <<EOF
{
  "name": "${pkg_name}",
  "version": "1.0.${i}",
  "license": "${license}"
}
EOF
            current_dir="${pkg_path}/node_modules"
            mkdir -p "${current_dir}" # Create nested node_modules for next level
        done
    done
}
