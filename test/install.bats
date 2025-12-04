#!/usr/bin/env bats
# Tests for install.sh

load test_helper

setup() {
    # Create a mock HOME directory for testing install.sh
    MOCK_HOME="${BATS_TEST_TMPDIR}/mock_home"
    mkdir -p "${MOCK_HOME}"

    # Save original HOME
    ORIGINAL_HOME="${HOME}"
    export HOME="${MOCK_HOME}"

    # Create dummy .bashrc and .zshrc in mock HOME
    touch "${HOME}/.bashrc"
    touch "${HOME}/.zshrc"

    # Derive the repo root from BATS_TEST_DIRNAME (test/ directory, so go up one level)
    export SOURCE_ROOT_OVERRIDE="${BATS_TEST_DIRNAME}/.."
    export INSTALL_SH="${SOURCE_ROOT_OVERRIDE}/install.sh"
}

teardown() {
    cd /
    [[ -n "${REPO_DIR:-}" ]] && rm -rf "${REPO_DIR}"
    [[ -n "${MOCK_HOME:-}" ]] && rm -rf "${MOCK_HOME}"

    # Restore original HOME
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="${ORIGINAL_HOME}"
    fi

    unset MOCK_HOME REPO_DIR ORIGINAL_HOME SOURCE_ROOT_OVERRIDE INSTALL_SH
}

@test "install.sh: copies files to destination" {
    # Run install.sh from within the test repo context
    "${INSTALL_SH}"

    # Assert destination directory exists
    [ -d "${MOCK_HOME}/.totally-legal-bro" ]

    # Assert core files are copied
    [ -f "${MOCK_HOME}/.totally-legal-bro/totally-legal-bro" ]
    [ -d "${MOCK_HOME}/.totally-legal-bro/lib" ]
    [ -d "${MOCK_HOME}/.totally-legal-bro/licenses" ]
}

@test "install.sh: makes binaries executable" {
    "${INSTALL_SH}"

    # Assert main executable is executable
    [ -x "${MOCK_HOME}/.totally-legal-bro/totally-legal-bro" ]

    # Assert lib scripts are executable
    [ -x "${MOCK_HOME}/.totally-legal-bro/lib/check.sh" ]
    [ -x "${MOCK_HOME}/.totally-legal-bro/lib/fix.sh" ]
}

@test "install.sh: adds to PATH in .bashrc" {
    "${INSTALL_SH}"

    # Assert PATH is added to .bashrc (format-agnostic)
    run grep -F "${MOCK_HOME}/.totally-legal-bro" "${HOME}/.bashrc"
    [ "$status" -eq 0 ]
}

@test "install.sh: adds to PATH in .zshrc" {
    "${INSTALL_SH}"

    # Assert PATH is added to .zshrc (format-agnostic)
    run grep -F "${MOCK_HOME}/.totally-legal-bro" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]
}

@test "install.sh: does not duplicate PATH entries" {
    # First install
    "${INSTALL_SH}" > /dev/null

    # Run again, it should detect and not add again
    # We must pipe 'y' because the directory exists
    run bash -c "echo 'y' | ${INSTALL_SH}"
    [ "$status" -eq 0 ]
    
    # Count occurrences of the installed directory path
    run grep -F -c "${MOCK_HOME}/.totally-legal-bro" "${HOME}/.bashrc"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "install.sh: handles overwrite confirmation" {
    # First install
    "${INSTALL_SH}" > /dev/null

    # Run again and answer 'n'
    run bash -c "echo 'n' | ${INSTALL_SH}"

    # Note: read -p might not print prompt when not TTY, so we check for the abort message
    assert_output_contains "Aborting install."
}

@test "install.sh: allows overwriting with 'y'" {
    # First install
    "${INSTALL_SH}" > /dev/null

    # Create a unique file in the installation dir
    echo "OLD CONTENT" > "${MOCK_HOME}/.totally-legal-bro/test_file.txt"

    # Run again and answer 'y'
    run bash -c "echo 'y' | ${INSTALL_SH}"

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