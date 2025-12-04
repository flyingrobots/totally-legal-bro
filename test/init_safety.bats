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
    # 1. License: MIT
    # 2. Owner: "Acme\ Corp" (Using backslash)
    # 3. Hook: n
    # 4. CI: n
    # 5. Deps: (empty line to finish)
    
    # Note: We need to be careful with echo and escaping.
    # We want to send literal: MIT, newline, Acme\ Corp, newline...
    
    printf "MIT\nAcme\\ Corp\n\n\nn\n" | totally-legal-bro init

    [ -f .legalbro.json ]
    
    # Read the ownerName field from the generated JSON
    owner=$(jq -r '.ownerName' .legalbro.json)
    
    # Without 'read -r', "Acme\ Corp" becomes "Acme Corp" (backslash space usually keeps space but might lose backslash depending on shell)
    # Actually "Acme\ Corp" -> read -> "Acme Corp" (backslash escapes the space)
    
    echo "Owner in JSON: '${owner}'"
    [ "${owner}" = "Acme\\ Corp" ]
}
