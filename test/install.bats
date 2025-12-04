#!/usr/bin/env bats
# Tests for install.sh

load test_helper

setup() {
    # Create a mock HOME directory for testing install.sh
    MOCK_HOME="${BATS_TEST_TMPDIR}/mock_home"
    mkdir -p "${MOCK_HOME}"
    export HOME="${MOCK_HOME}"

    # Create dummy .bashrc and .zshrc in mock HOME
    touch "${HOME}/.bashrc"
    touch "${HOME}/.zshrc"

    # Set SOURCE_ROOT_OVERRIDE for install.sh to Docker's /app
    export SOURCE_ROOT_OVERRIDE="/app"
}

teardown() {
    cd /
    [[ -n "${REPO_DIR:-}" ]] && rm -rf "${REPO_DIR}"
    rm -rf "${MOCK_HOME}"
    unset HOME
}

@test "install.sh: copies files to destination" {
    # Run install.sh from within the test repo context
    /app/install.sh

    # Assert destination directory exists
    [ -d "${MOCK_HOME}/.totally-legal-bro" ]

    # Assert core files are copied
    [ -f "${MOCK_HOME}/.totally-legal-bro/totally-legal-bro" ]
    [ -d "${MOCK_HOME}/.totally-legal-bro/lib" ]
    [ -d "${MOCK_HOME}/.totally-legal-bro/licenses" ]
}

@test "install.sh: makes binaries executable" {
    /app/install.sh

    # Assert main executable is executable
    [ -x "${MOCK_HOME}/.totally-legal-bro/totally-legal-bro" ]

    # Assert lib scripts are executable
    [ -x "${MOCK_HOME}/.totally-legal-bro/lib/check.sh" ]
    [ -x "${MOCK_HOME}/.totally-legal-bro/lib/fix.sh" ]
}

@test "install.sh: adds to PATH in .bashrc" {
    /app/install.sh

    # Assert PATH is added to .bashrc
    # Check if the expected line exists in the file
    run cat "${HOME}/.bashrc"
    assert_output_contains "export PATH=\"${MOCK_HOME}/.totally-legal-bro:\$PATH\""
}

@test "install.sh: adds to PATH in .zshrc" {
    /app/install.sh

    # Assert PATH is added to .zshrc
    run cat "${HOME}/.zshrc"
    assert_output_contains "export PATH=\"${MOCK_HOME}/.totally-legal-bro:\$PATH\""
}

@test "install.sh: does not duplicate PATH entries" {
    # First install
    /app/install.sh > /dev/null

    # Run again, it should detect and not add again
    # We must pipe 'y' because the directory exists
    run bash -c "echo 'y' | /app/install.sh"
    
    # Count occurrences of the export line
    run grep -c "export PATH=\"${MOCK_HOME}/.totally-legal-bro:\$PATH\"" "${HOME}/.bashrc"
    [ "$output" = "1" ]
}

@test "install.sh: handles overwrite confirmation" {
    # First install
    /app/install.sh > /dev/null

    # Run again and answer 'n'
    run bash -c "echo 'n' | /app/install.sh"
    
    # Note: read -p might not print prompt when not TTY, so we check for the abort message
    assert_output_contains "Aborting install."
}

@test "install.sh: allows overwriting with 'y'" {
    # First install
    /app/install.sh > /dev/null

    # Create a unique file in the installation dir
    echo "OLD CONTENT" > "${MOCK_HOME}/.totally-legal-bro/test_file.txt"

    # Run again and answer 'y'
    run bash -c "echo 'y' | /app/install.sh"

    # Check that it proceeded (installed files)
    assert_output_contains "Installing totally-legal-bro"
    assert_output_contains "Done."

    # Verify the unique file is gone (overwritten/removed during install process?)
    # Actually install.sh just copies OVER existing directory (cp -R). 
    # It does NOT delete the directory first. 
    # So "test_file.txt" might actually still be there if cp merges folders.
    # Let's check install.sh logic: `mkdir -p "${DEST}"` then `cp -R ...`.
    # This is a merge.
    
    # So we can't verify overwrite by file absence.
    # But we verified it printed "Installing...", so it didn't abort.
}