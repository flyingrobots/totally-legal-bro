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
