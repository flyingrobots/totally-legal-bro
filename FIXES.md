# Recommended Fixes

This document tracks identified issues and optimization opportunities for `totally-legal-bro`. Each item includes a prompt to guide an LLM in implementing the fix.

## P0: Critical Performance & Safety (Immediate Action Required)

- [x] **Optimize `deps.sh` scan loop:**
    Refactor `scan_dependencies` in `lib/deps.sh`. currently, it finds all `package.json` files and loops over them, invoking `jq` *twice* per file. For large `node_modules`, this spawns thousands of subprocesses and is extremely slow.
    **Task:** Rewrite the loop to use `find ... -exec jq ...` or `xargs` to process files in batches, or at minimum, run `jq` once per file to extract both `.name` and `.license` simultaneously. Ensure it still correctly handles the `while read` loop for the output.

- [x] **Fix dangerous `cd` in tests (SC2164):**
    In `test/test_helper.bash`, the `setup_test_repo` function does `cd "${repo_dir}"` without error handling. If this fails, subsequent commands (like `rm -rf` in teardown) could run in the wrong directory.
    **Task:** Change `cd "${repo_dir}"` to `cd "${repo_dir}" || exit 1` (or `return 1`). Apply this fix to any other `cd` commands in the test suite.

- [x] **Safe `read` in `init.sh` (SC2162):**
    In `lib/init.sh`, multiple `read` commands are missing the `-r` flag, allowing backslashes to escape characters (e.g., in file paths or names).
    **Task:** Update all instances of `read variable` to `read -r variable` in `lib/init.sh`.

## P1: Maintainability & Logic Refactoring (High Priority)

- [x] **DRY Source File Detection:**
    The logic to identify source files (the list of extensions like `.js|.py|.go...` and the `find` command fallback) is duplicated in `lib/check.sh` (`headers_status`) and `lib/fix.sh` (`fix_source_headers`).
    **Task:** Extract this logic into a new function `get_source_files` in a shared library (e.g., create `lib/utils.sh` or add to `lib/config.sh`). Update `check.sh` and `fix.sh` to use this function instead of hardcoded logic.

- [x] **Fix `install.sh` shellcheck exclusions:**
    The `install.sh` script is currently excluded from some shellcheck scans or has minor issues.
    **Task:** Run `shellcheck install.sh` and fix any warnings (e.g., quoting variables, safe paths). Ensure it adheres to the project's strict mode.

## P2: Robustness & Edge Cases

- [x] **Safe Git Hook Installation:**
    In `lib/init.sh`, `setup_git_hook` appends to `.git/hooks/pre-commit` without creating a backup.
    **Task:** Modify `setup_git_hook` to back up an existing `pre-commit` hook (e.g., to `pre-commit.bak`) before appending or modifying it, and print a message informing the user.

- [ ] **Standardize Shebangs:**
    Some scripts use `#!/usr/bin/env bash` and others might be inconsistent.
    **Task:** Verify all `.sh` and `.bats` files use the portable `#!/usr/bin/env bash` shebang.

## P3: Documentation & Polish

- [ ] **Add missing `install.sh` tests:**
    There are no automated tests for `install.sh`.
    **Task:** Create `test/install.bats` to verify the installer correctly copies files to the destination, handles existing directories, and sets permissions.

- [ ] **Update `docs/SPEC.md`:**
    Ensure the specification document reflects the recent changes (transitive dependency scanning, portable regex fixes).
    **Task:** Review `docs/SPEC.md` and update the "Dependency Scanning" and "Fix Command" sections to match the current implementation.
