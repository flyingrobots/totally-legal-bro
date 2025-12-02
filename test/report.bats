#!/usr/bin/env bats
# Tests for the 'report' command

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "report: shows configuration summary" {
    create_config "MIT" "Test Company"

    run_tlb report

    assert_output_contains "Configuration"
    assert_output_contains "Required License: MIT"
    assert_output_contains "Owner Name: Test Company"
}

@test "report: shows dependency policy" {
    create_config "Apache-2.0" "Test"

    run_tlb report

    assert_output_contains "Dependency Policy:"
    assert_output_contains "MIT"
    assert_output_contains "Apache-2.0"
}

@test "report: shows overall compliance status" {
    create_config "MIT" "Test"

    # Create a non-compliant repo
    run_tlb report

    assert_output_contains "Overall Status:"
    assert_output_contains "NON-COMPLIANT"
}

@test "report: shows COMPLIANT when all checks pass" {
    create_config "MIT" "Test Owner"

    # Create compliant repo
    cat > LICENSE <<EOF
MIT License
Copyright (c) 2024 Test Owner
EOF

    cat > README.md <<EOF
# Project
## License
MIT
EOF

    cat > NOTICE <<EOF
NOTICE
EOF

    git add LICENSE README.md NOTICE

    run_tlb report

    assert_output_contains "COMPLIANT"
    assert_output_contains "legally chill"
}

@test "report: lists files missing headers" {
    create_config "MIT" "Test"
    echo "MIT" > LICENSE
    cat > README.md <<EOF
# Test
## License
MIT
EOF
    git add LICENSE README.md

    # Add files without headers
    echo "code" > missing1.js
    echo "code" > missing2.py
    git add missing1.js missing2.py

    run_tlb report

    assert_output_contains "Files needing headers:"
    assert_output_contains "missing1.js"
    assert_output_contains "missing2.py"
}

@test "report: shows source file statistics" {
    create_config "MIT" "Test"
    echo "MIT" > LICENSE
    cat > README.md <<EOF
# Test
## License
MIT
EOF
    git add LICENSE README.md

    # Add mix of good and bad files
    cat > good.js <<EOF
/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2024 Test
 */
code here
EOF

    echo "bad code" > bad.js

    git add good.js bad.js

    run_tlb report

    assert_output_contains "Total files: 2"
    assert_output_contains "Valid headers:"
    assert_output_contains "Missing headers:"
}

@test "report: provides actionable fix suggestions" {
    create_config "MIT" "Test"

    run_tlb report

    assert_output_contains "totally-legal-bro fix"
}
