#!/usr/bin/env bats
# Tests for the 'init' command

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "init: creates config file with required fields" {
    # Simulate user input (license, owner, dep policy, git hook=n, CI=n)
    echo -e "MIT\nTest Company\n\nn\nn" | totally-legal-bro init

    # Check config was created
    [ -f .legalbro.json ]

    # Validate JSON structure
    run jq -r '.requiredLicense' .legalbro.json
    [ "$output" = "MIT" ]

    run jq -r '.ownerName' .legalbro.json
    [ "$output" = "Test Company" ]
}

@test "init: creates GitHub Actions workflow" {
    echo -e "Apache-2.0\nAcme Corp\n\ny" | totally-legal-bro init

    [ -f .github/workflows/legal-bro.yml ]

    # Check workflow contains the check command
    run grep "totally-legal-bro check" .github/workflows/legal-bro.yml
    [ "$status" -eq 0 ]
}

@test "init: sets up git pre-commit hook" {
    # Create .git directory first
    git init

    echo -e "MIT\nTest\n\ny\nn" | totally-legal-bro init

    [ -f .git/hooks/pre-commit ]
    [ -x .git/hooks/pre-commit ]

    # Check hook contains our command
    run grep "totally-legal-bro check" .git/hooks/pre-commit
    [ "$status" -eq 0 ]
}

@test "init: warns when config already exists" {
    # Create existing config
    echo '{"requiredLicense": "MIT", "ownerName": "Existing"}' > .legalbro.json

    # Try to init again (answer 'n' to overwrite)
    run bash -c 'echo "n" | totally-legal-bro init'

    assert_output_contains "already exists"
    assert_output_contains "Aborting"
}

@test "init: allows overwriting existing config" {
    # Create existing config
    echo '{"requiredLicense": "MIT", "ownerName": "Old"}' > .legalbro.json

    # Overwrite it
    echo -e "y\nApache-2.0\nNew Owner\n\nn\nn" | totally-legal-bro init

    run jq -r '.requiredLicense' .legalbro.json
    [ "$output" = "Apache-2.0" ]

    run jq -r '.ownerName' .legalbro.json
    [ "$output" = "New Owner" ]
}

@test "init: handles dependency policy input" {
    echo -e "MIT\nTest\nMIT\nApache-2.0\nBSD-3-Clause\n\nn\nn" | totally-legal-bro init

    # Check all three licenses are in the policy
    run jq -r '.dependencyPolicy | length' .legalbro.json
    [ "$output" = "3" ]

    run jq -r '.dependencyPolicy[0]' .legalbro.json
    [ "$output" = "MIT" ]
}

@test "init: backs up existing pre-commit hook (P2)" {
    # Create a git repo
    git init >/dev/null 2>&1

    # Create a dummy pre-commit hook
    mkdir -p .git/hooks
    echo "#!/bin/bash" > .git/hooks/pre-commit
    echo "echo 'Original hook content'" >> .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

    # Run init, say yes to hook setup
    # License, Owner, Dep Policy blank, Git hook yes, CI no
    echo -e "MIT\nTest User\n\ny\nn" | totally-legal-bro init >/dev/null 2>&1
    
    # Assert backup file exists
    [ -f .git/hooks/pre-commit.bak ]

    # Assert backup file contains original content
    run grep "Original hook content" .git/hooks/pre-commit.bak
    [ "$status" -eq 0 ]

    # Assert new pre-commit hook contains both original and new content
    run grep "Original hook content" .git/hooks/pre-commit
    [ "$status" -eq 0 ]
    run grep "totally-legal-bro check" .git/hooks/pre-commit
    [ "$status" -eq 0 ]

    # Ensure the merged hook remains executable
    [ -x .git/hooks/pre-commit ]
}

@test "init: is idempotent with existing hook marker" {
    # Create a git repo
    git init >/dev/null 2>&1

    # Create a pre-commit hook that already contains the totally-legal-bro check line
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
echo "Existing hook logic"
totally-legal-bro check
echo "More existing logic"
EOF
    chmod +x .git/hooks/pre-commit

    # Run init twice with the same answers
    echo -e "MIT\nTest User\n\ny\nn" | totally-legal-bro init >/dev/null 2>&1
    echo -e "MIT\nTest User\n\ny\nn" | totally-legal-bro init >/dev/null 2>&1

    # Assert that NO backup file was created (because marker already existed)
    backup_count=$(find .git/hooks -name "pre-commit.bak*" 2>/dev/null | wc -l)
    [ "${backup_count}" -eq 0 ]

    # Assert the pre-commit hook contains exactly one totally-legal-bro check line
    check_count=$(grep -c "totally-legal-bro check" .git/hooks/pre-commit || echo 0)
    [ "${check_count}" -eq 1 ]

    # Assert the merged hook remains executable
    [ -x .git/hooks/pre-commit ]

    # Assert original content is preserved
    run grep "Existing hook logic" .git/hooks/pre-commit
    [ "$status" -eq 0 ]
    run grep "More existing logic" .git/hooks/pre-commit
    [ "$status" -eq 0 ]
}
