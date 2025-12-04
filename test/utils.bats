#!/usr/bin/env bats
# Tests for lib/utils.sh

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "get_source_files: correctly identifies source files in a git repo" {
    source /app/lib/utils.sh # Source from absolute path in Docker container

    # Create various files
    create_source_file "src/main.js" "console.log('hello');"
    create_source_file "src/util.py" "print('hello')"
    create_source_file "README.md" "# README"
    create_source_file "config.json" "{}"
    create_source_file "image.png" "binarydata"
    create_source_file "script.sh" "#!/bin/bash"
    
    # Add some untracked but matching files (DO NOT git add this one)
    mkdir -p tmp
    create_source_file "tmp/temp.js" "temp code" true # Pass true for no_git_add

    run get_source_files
    
    [ "$status" -eq 0 ]
    
    # Expected source files
    assert_output_contains "src/main.js"
    assert_output_contains "src/util.py"
    assert_output_contains "script.sh"
    
    # Expected non-source or excluded files (should not be in output)
    assert_output_not_contains "README.md"
    assert_output_not_contains "config.json"
    assert_output_not_contains "image.png"
    assert_output_not_contains "tmp/temp.js" # This should now truly be untracked and not show up
}

@test "get_source_files: falls back to find if not a git repo" {
    # Delete .git to simulate non-git repo
    rm -rf .git || true
    
    source /app/lib/utils.sh # Source from absolute path in Docker container

    # Create various files (do not git add them)
    create_source_file "src/main.js" "console.log('hello');" true
    create_source_file "src/util.py" "print('hello')" true
    create_source_file "README.md" "# README" true
    create_source_file "config.json" "{}" true
    create_source_file "image.png" "binarydata" true
    create_source_file "script.sh" "#!/bin/bash" true
    
    # No git add needed for these
    # No git rm --cached -r . needed either, as they were never added
    
    run get_source_files
    
    [ "$status" -eq 0 ]
    
    # Expected source files (all files created will be found by find)
    assert_output_contains "src/main.js"
    assert_output_contains "src/util.py"
    assert_output_contains "script.sh"
    
    # Expected non-source or excluded files (should not be in output)
    assert_output_not_contains "README.md"
    assert_output_not_contains "config.json"
    assert_output_not_contains "image.png"
}
