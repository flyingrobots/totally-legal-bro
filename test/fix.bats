#!/usr/bin/env bats
# Tests for the 'fix' command

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "fix: creates LICENSE file when missing" {
    create_config "MIT" "Test Owner"

    run_tlb fix

    [ -f LICENSE ]
    run grep "MIT" LICENSE
    [ "$status" -eq 0 ]
}

@test "fix: creates NOTICE file when missing" {
    create_config "MIT" "Test Owner"

    run_tlb fix

    [ -f NOTICE ]
    run grep "Test Owner" NOTICE
    [ "$status" -eq 0 ]
}

@test "fix: creates README.md with license section" {
    create_config "Apache-2.0" "Acme Corp"

    run_tlb fix

    [ -f README.md ]
    run grep "Apache-2.0" README.md
    [ "$status" -eq 0 ]
    run grep "License" README.md
    [ "$status" -eq 0 ]
}

@test "fix: appends license section to existing README" {
    create_config "MIT" "Test"

    cat > README.md <<EOF
# My Project

Some content here.
EOF
    git add README.md

    run_tlb fix

    # Check original content still there
    run grep "My Project" README.md
    [ "$status" -eq 0 ]

    # Check license section was added
    run grep "## License" README.md
    [ "$status" -eq 0 ]
}

@test "fix: injects headers into source files without headers" {
    create_config "MIT" "Test Owner"

    # Create source file without header
    cat > script.sh <<EOF
#!/bin/bash
echo "hello"
EOF
    git add script.sh

    run_tlb fix

    # Check header was injected
    run head -n 5 script.sh
    assert_output_contains "SPDX-License-Identifier: MIT"
    assert_output_contains "Copyright"
    assert_output_contains "Test Owner"

    # Check shebang is still first
    run head -n 1 script.sh
    assert_output_contains "#!/bin/bash"
}

@test "fix: handles JavaScript files with block comments" {
    create_config "Apache-2.0" "JS Corp"

    cat > app.js <<EOF
function main() {
    console.log("test");
}
EOF
    git add app.js

    run_tlb fix

    run head -n 5 app.js
    assert_output_contains "/*"
    assert_output_contains "SPDX-License-Identifier: Apache-2.0"
    assert_output_contains "Copyright"
    assert_output_contains "*/"
}

@test "fix: handles Python files with # comments" {
    create_config "MIT" "Python Dev"

    cat > script.py <<EOF
def main():
    print("hello")
EOF
    git add script.py

    run_tlb fix

    run head -n 5 script.py
    assert_output_contains "# SPDX-License-Identifier: MIT"
    assert_output_contains "# Copyright"
}

@test "fix: preserves shebang when injecting headers" {
    create_config "MIT" "Test"

    cat > tool.py <<EOF
#!/usr/bin/env python3
print("test")
EOF
    git add tool.py

    run_tlb fix

    # Shebang should still be first line
    run head -n 1 tool.py
    [ "$output" = "#!/usr/bin/env python3" ]

    # Header should come after
    run head -n 10 tool.py
    assert_output_contains "SPDX-License-Identifier"
}

@test "fix: does not modify files that already have headers" {
    create_config "MIT" "Test Owner"

    cat > good.js <<EOF
/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2024 Test Owner
 */

console.log("already good");
EOF
    git add good.js

    # Save original
    cp good.js good.js.backup

    run_tlb fix

    # File should be unchanged
    run diff good.js good.js.backup
    [ "$status" -eq 0 ]
}

@test "fix: reports number of fixes made" {
    create_config "MIT" "Test"

    # Create multiple files needing fixes
    echo "code" > file1.js
    echo "code" > file2.py
    echo "code" > file3.sh
    git add file1.js file2.py file3.sh

    run_tlb fix

    assert_output_contains "Fixed"
    # Should fix: LICENSE, NOTICE, README, and 3 source files = 6 total
    assert_output_contains "6"
}
