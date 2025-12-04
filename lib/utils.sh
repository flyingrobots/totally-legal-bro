#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Shared utility functions

# Returns a list of source files in the current git repository.
# Prioritizes git ls-files, falls back to find if not a git repo.
function get_source_files() {
    local files
    
    # Define common source file extensions
    # Exclude typical config/data files that might be caught by ls-files
    local SOURCE_FILE_EXTENSIONS='\.(sh|bash|py|js|ts|tsx|jsx|go|rs|c|cpp|h|hpp|java|rb|php|tex)$'
    local EXCLUDED_FILE_TYPES='\.(json|toml|yaml|yml|xml|md|txt)$'

    # Check if in a git repository
    if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
        files=$(git ls-files | grep -E "${SOURCE_FILE_EXTENSIONS}" | grep -v -E "${EXCLUDED_FILE_TYPES}" || true)
    else
        # Fallback to find if not a git repo or git command fails
        files=$(find . -type f \
                    \( -name "*.sh" -o -name "*.bash" -o -name "*.py" -o \
                       -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o \
                       -name "*.jsx" -o -name "*.go" -o -name "*.rs" -o \
                       -name "*.c" -o -name "*.cpp" -o -name "*.h" -o \
                       -name "*.hpp" -o -name "*.java" -o -name "*.rb" -o \
                       -name "*.php" -o -name "*.tex" \) \
                    -not -regex ".*${EXCLUDED_FILE_TYPES}" \
                    || true)
    fi

    echo "${files}"
}
