#!/usr/bin/env bats
# Tests for the 'check' command

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "check: fails when no config exists" {
    run_tlb check

    [ "$status" -eq 1 ]
    assert_output_contains "Config file not found"
}

@test "check: fails when config is invalid JSON" {
    echo "not valid json {{{" > .legalbro.json

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "Invalid JSON"
}

@test "check: fails when required fields are missing" {
    echo '{"ownerName": "Test"}' > .legalbro.json

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "Missing required field 'requiredLicense'"
}

@test "check: fails when LICENSE file is missing" {
    create_config "MIT" "Test Owner"

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "LICENSE file not found"
}

@test "check: fails when LICENSE has wrong SPDX" {
    create_config "MIT" "Test Owner"
    echo "Apache License 2.0" > LICENSE
    git add LICENSE

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "does not contain 'MIT'"
}

@test "check: passes when LICENSE is correct" {
    create_config "MIT" "Test Owner"
    cat > LICENSE <<EOF
MIT License

Copyright (c) 2024 Test Owner

Permission is hereby granted...
EOF
    git add LICENSE

    # Still fails because README is missing
    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "LICENSE file"
    assert_output_contains "PASS"
}

@test "check: warns when NOTICE file is missing" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    git add LICENSE

    run_tlb check
    assert_output_contains "NOTICE"
}

@test "check: fails when README missing" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    git add LICENSE

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "README.md not found"
}

@test "check: fails when README has no license section" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    echo "# My Project" > README.md
    git add LICENSE README.md

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "should mention the license"
}

@test "check: detects missing headers in source files" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    cat > README.md <<EOF
# Project
## License
MIT
EOF
    git add LICENSE README.md

    # Create source file without header
    create_source_file "src/main.js" "console.log('hello');"

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "missing proper headers"
    assert_output_contains "src/main.js"
}

@test "check: passes when source files have proper headers" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    cat > README.md <<EOF
# Project
## License
MIT
EOF
    git add LICENSE README.md

    # Create source file WITH header
    mkdir -p src
    cat > src/main.js <<EOF
/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2024 Test Owner
 */

console.log('hello');
EOF
    git add src/main.js

    run_tlb check
    [ "$status" -eq 0 ]
    assert_output_contains "All checks passed"
}

@test "check: ignores non-source files" {
    create_config "MIT" "Test Owner"
    echo "MIT License" > LICENSE
    cat > README.md <<EOF
# Project
## License
MIT
EOF
    git add LICENSE README.md

    # Create non-source files (should be ignored)
    echo "Binary data" > image.png
    echo "Some text" > notes.txt
    git add image.png notes.txt

    run_tlb check
    [ "$status" -eq 0 ]
}

@test "check: warnings do not cause check to fail" {
    create_config "MIT" "Test Owner"

    # Create valid LICENSE and README (will pass)
    cat > LICENSE <<EOF
MIT License

Copyright (c) 2025 Test Owner

Permission is hereby granted...
EOF
    git add LICENSE

    cat > README.md <<EOF
# Project
## License
MIT
EOF
    git add README.md

    # No NOTICE file - will warn
    # Create package.json but no dependencyPolicy - will warn
    cat > package.json <<'EOF'
{
  "name": "test",
  "version": "1.0.0"
}
EOF
    git add package.json

    # Check should pass despite warnings
    run_tlb check
    [ "$status" -eq 0 ]
    assert_output_contains "All checks passed"
    assert_output_contains "WARN"
}

@test "check: actual failures still cause check to fail" {
    create_config "MIT" "Test Owner"

    # Missing LICENSE - will fail
    cat > README.md <<EOF
# Project
## License
MIT
EOF
    git add README.md

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "check(s) failed"
    assert_output_contains "LICENSE file not found"
}
