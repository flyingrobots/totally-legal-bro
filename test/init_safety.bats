#!/usr/bin/env bats
# Tests for safety and robustness of 'init' command

load test_helper

setup() {
    REPO_DIR=$(setup_test_repo)
    cd "${REPO_DIR}"
}

teardown() {
    cd /
    rm -rf "${REPO_DIR}"
}

@test "init: preserves backslashes in user input (SC2162)" {
    # Simulate user input:
    # 1. Required License: MIT
    # 2. Owner Name: Acme\ Corp
    # 3. Dependency Policy: (empty line to finish)
    # 4. Git hook setup: n
    # 5. CI workflow setup: n
    printf "MIT\nAcme\\\ Corp\n\n\nn\n" | totally-legal-bro init

    [ -f .legalbro.json ]
    
    # Read the ownerName field from the generated JSON
    owner=$(jq -r '.ownerName' .legalbro.json)
    
    # Without 'read -r', "Acme\ Corp" becomes "Acme Corp" (backslash space usually keeps space but might lose backslash depending on shell)
    # Actually "Acme\ Corp" -> read -> "Acme Corp" (backslash escapes the space)
    
    echo "Owner in JSON: '${owner}'"
    [ "${owner}" = "Acme\\ Corp" ]
}
