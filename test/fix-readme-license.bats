#!/usr/bin/env bats
# Tests for README license section detection and appending

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "fix: does not duplicate '## License' section" {
    create_config "MIT" "Test"

    cat > README.md <<'EOF'
# My Project

Some content here.

## License

This project is licensed under MIT.
EOF
    git add README.md

    run_tlb fix

    # Count how many times "## License" appears
    local count=$(grep -c "## License" README.md)
    [ "$count" -eq 1 ]
}

@test "fix: does not duplicate '## LICENSE' (uppercase) section" {
    create_config "Apache-2.0" "Test"

    cat > README.md <<'EOF'
# My Project

## LICENSE

Apache-2.0
EOF
    git add README.md

    run_tlb fix

    # Check that "LICENSE" heading appears exactly once
    local count=$(grep -c "^## LICENSE" README.md)
    [ "$count" -eq 1 ]
}

@test "fix: does not duplicate '## §11. LICENSE' (statute format)" {
    create_config "Apache-2.0" "Test"

    cat > README.md <<'EOF'
# THE TOTALLY-LEGAL-BRO ACT

## §11. LICENSE

This project is licensed under Apache-2.0.
EOF
    git add README.md

    run_tlb fix

    # Should not append another section
    local count=$(grep -c "^## " README.md)
    [ "$count" -eq 1 ]
}

@test "fix: does not duplicate '### License' (3rd level heading)" {
    create_config "MIT" "Test"

    cat > README.md <<'EOF'
# Project

## Documentation

### License

MIT License applies.
EOF
    git add README.md

    run_tlb fix

    local count=$(grep -ci "^###.*license" README.md)
    [ "$count" -eq 1 ]
}

@test "fix: appends license section when truly missing" {
    create_config "MIT" "Test"

    cat > README.md <<'EOF'
# Project

## Features

- Feature 1
- Feature 2

## Installation

Run `npm install`.
EOF
    git add README.md

    run_tlb fix

    # Should now have a license section
    run grep -i "license" README.md
    [ "$status" -eq 0 ]

    # Check it's actually a heading
    run grep "^## License$" README.md
    [ "$status" -eq 0 ]
}

@test "fix: does NOT falsely detect 'Legal' as 'License'" {
    create_config "Apache-2.0" "Test"

    cat > README.md <<'EOF'
# Project

## Legal

This software is licensed under Apache-2.0.
EOF
    git add README.md

    run_tlb fix

    # Should append a proper License section since "Legal" != "License"
    # Check that we now have both "Legal" and "License" sections
    run grep "^## Legal" README.md
    [ "$status" -eq 0 ]

    run grep "^## License" README.md
    [ "$status" -eq 0 ]
}

@test "fix: case-insensitive detection works" {
    create_config "MIT" "Test"

    cat > README.md <<'EOF'
# Project

## license

MIT
EOF
    git add README.md

    run_tlb fix

    # Should not duplicate (case-insensitive match)
    local count=$(grep -ci "^##.*license" README.md)
    [ "$count" -eq 1 ]
}
