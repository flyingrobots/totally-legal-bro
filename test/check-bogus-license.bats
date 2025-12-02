#!/usr/bin/env bats
# Tests for detecting bogus/placeholder LICENSE files

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "check: detects placeholder '[Full text here]' in LICENSE" {
    create_config "MIT" "Test"

    cat > LICENSE <<'EOF'
MIT License

[Full text here]

Copyright 2024 Test
EOF
    git add LICENSE

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "placeholder text"
}

@test "check: detects '[yyyy]' placeholder in LICENSE" {
    create_config "Apache-2.0" "Test"

    cat > LICENSE <<'EOF'
Apache License 2.0

Copyright [yyyy] [name of copyright owner]
EOF
    git add LICENSE

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "placeholder text"
    assert_output_contains "yyyy"
}

@test "check: detects 'TODO' in LICENSE" {
    create_config "MIT" "Test"

    cat > LICENSE <<'EOF'
MIT License

TODO: Fill in license text

Copyright 2024 Test
EOF
    git add LICENSE

    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "placeholder text"
    assert_output_contains "TODO"
}

@test "check: passes with real canonical Apache 2.0 license" {
    create_config "Apache-2.0" "Test Owner"

    # Use the actual canonical Apache template
    sed -e "s/\[yyyy\]/2025/g" \
        -e "s/\[name of copyright owner\]/Test Owner/g" \
        /app/licenses/templates/Apache-2.0.txt > LICENSE

    cat > README.md <<EOF
# Test
## License
Apache-2.0
EOF

    git add LICENSE README.md

    run_tlb check
    [ "$status" -eq 0 ]
    assert_output_contains "All checks passed"
}

@test "check: passes with real canonical MIT license" {
    create_config "MIT" "Test Owner"

    # Use the actual canonical MIT template
    sed -e "s/<year>/2025/g" \
        -e "s/<copyright holders>/Test Owner/g" \
        /app/licenses/templates/MIT.txt > LICENSE

    cat > README.md <<EOF
# Test
## License
MIT
EOF

    git add LICENSE README.md

    run_tlb check
    [ "$status" -eq 0 ]
    assert_output_contains "All checks passed"
}
