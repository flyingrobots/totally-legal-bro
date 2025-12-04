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

@test "fix: correctly replaces placeholders in Apache-2.0 license" {
    create_config "Apache-2.0" "Big Corp"

    run_tlb fix
    [ "$status" -eq 0 ]

    [ -f LICENSE ]

    # Should NOT contain placeholders
    run grep "\[yyyy\]" LICENSE
    [ "$status" -eq 1 ] # grep returns 1 if not found, which is what we want

    run grep "\[name of copyright owner\]" LICENSE
    [ "$status" -eq 1 ]

    # Should contain actual values
    run grep "Copyright .* Big Corp" LICENSE
    [ "$status" -eq 0 ]

    current_year=$(date +%Y)
    run grep "Copyright $current_year" LICENSE
    [ "$status" -eq 0 ]
}

@test "fix: regenerates existing LICENSE file with placeholder text" {
    create_config "MIT" "Test Owner"

    # Create a LICENSE with placeholder text (simulating incomplete license)
    cat > LICENSE <<'EOF'
MIT License

Copyright [yyyy] [name of copyright owner]

TODO: Add license text here
EOF
    git add LICENSE

    # Run fix - should detect placeholders and regenerate
    run_tlb fix
    [ "$status" -eq 0 ]

    # Should NOT contain placeholders anymore
    run grep "\[yyyy\]" LICENSE
    [ "$status" -eq 1 ]

    run grep "\[name of copyright owner\]" LICENSE
    [ "$status" -eq 1 ]

    run grep "TODO" LICENSE
    [ "$status" -eq 1 ]

    # Should contain actual values
    current_year=$(date +%Y)
    run grep "Copyright.*$current_year.*Test Owner" LICENSE
    [ "$status" -eq 0 ]

    # Should contain real MIT license text
    run grep "Permission is hereby granted" LICENSE
    [ "$status" -eq 0 ]
}

@test "fix: regenerates LICENSE with PLACEHOLDER keyword" {
    create_config "Apache-2.0" "Acme Inc"

    cat > LICENSE <<'EOF'
Apache License 2.0

PLACEHOLDER - Replace with full license text

Copyright 2025 Acme Inc
EOF
    git add LICENSE

    run_tlb fix
    [ "$status" -eq 0 ]

    # Should NOT contain PLACEHOLDER
    run grep "PLACEHOLDER" LICENSE
    [ "$status" -eq 1 ]

    # Should contain real Apache license
    run grep "TERMS AND CONDITIONS" LICENSE
    [ "$status" -eq 0 ]

    # Should contain the configured owner
    run grep "Acme Inc" LICENSE
    [ "$status" -eq 0 ]
}

@test "fix: regenerates LICENSE with wrong license type (Apache when MIT required)" {
    create_config "MIT" "Test Owner"

    # Create an Apache-2.0 LICENSE when config requires MIT
    cat > LICENSE <<'EOF'
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

Copyright 2025 Test Owner
EOF
    git add LICENSE

    cat > README.md <<'EOF'
# Test
## License
MIT
EOF
    git add README.md

    run_tlb fix
    [ "$status" -eq 0 ]

    # Should have regenerated the LICENSE
    run grep "MIT License" LICENSE
    [ "$status" -eq 0 ]

    # Should NOT contain Apache text
    run grep "TERMS AND CONDITIONS" LICENSE
    [ "$status" -eq 1 ]

    # Should contain MIT license text
    run grep "Permission is hereby granted" LICENSE
    [ "$status" -eq 0 ]

    # Should contain the configured owner
    run grep "Test Owner" LICENSE
    [ "$status" -eq 0 ]

    # Now check should pass
    run_tlb check
    [ "$status" -eq 0 ]
}

@test "fix: regenerates LICENSE with wrong license type (MIT when Apache required)" {
    create_config "Apache-2.0" "Big Corp"

    # Create an MIT LICENSE when config requires Apache-2.0
    cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2025 Big Corp

Permission is hereby granted, free of charge...
EOF
    git add LICENSE

    cat > README.md <<'EOF'
# Test
## License
Apache-2.0
EOF
    git add README.md

    run_tlb fix
    [ "$status" -eq 0 ]

    # Should have regenerated the LICENSE
    run grep "Apache License" LICENSE
    [ "$status" -eq 0 ]

    # Should contain Apache text
    run grep "TERMS AND CONDITIONS" LICENSE
    [ "$status" -eq 0 ]

    # Should NOT contain MIT text
    run grep "Permission is hereby granted" LICENSE
    [ "$status" -eq 1 ]

    # Should contain the configured owner
    run grep "Big Corp" LICENSE
    [ "$status" -eq 0 ]

    # Now check should pass
    run_tlb check
    [ "$status" -eq 0 ]
}

@test "fix: fixes source headers missing copyright symbol" {
    create_config "MIT" "Test Owner"

    # Create LICENSE and README so they pass
    cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2025 Test Owner

Permission is hereby granted...
EOF
    git add LICENSE

    cat > README.md <<'EOF'
# Test
## License
MIT
EOF
    git add README.md

    # Create source file with header but missing © or (c) symbol
    cat > script.sh <<'EOF'
#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright 2025 Test Owner

echo "test"
EOF
    git add script.sh

    # Check should fail because copyright missing symbol
    run_tlb check
    [ "$status" -eq 1 ]
    assert_output_contains "missing proper headers"

    # Fix should detect and fix it
    run_tlb fix

    # Now check should pass
    run_tlb check
    [ "$status" -eq 0 ]

    # File should now have proper copyright with symbol
    run head -10 script.sh
    assert_output_contains "Copyright © 2025 Test Owner"
}
