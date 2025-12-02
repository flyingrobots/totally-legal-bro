#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Fix command: Auto-repair missing headers and files

declare -i FIX_COUNT=0

function cmd_fix() {
    echo -e "${BLUE}🔧 Auto-fixing legal compliance issues...${NC}"
    echo ""

    # Validate config exists
    if ! validate_config; then
        exit 1
    fi

    local required_license
    local owner_name
    local current_year

    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")
    current_year=$(date +%Y)

    echo "Config: License=${required_license}, Owner=${owner_name}"
    echo ""

    # Run all fixes
    fix_license_file "${required_license}" "${owner_name}" "${current_year}"
    fix_notice_file "${owner_name}"
    fix_readme_license "${required_license}"
    fix_source_headers "${required_license}" "${owner_name}" "${current_year}"

    echo ""
    if [[ ${FIX_COUNT} -eq 0 ]]; then
        echo -e "${GREEN}No issues found to fix${NC}"
    else
        echo -e "${GREEN}✓ Fixed ${FIX_COUNT} issue(s)${NC}"
        echo ""
        echo "Run 'totally-legal-bro check' to verify"
    fi
}

function fix_license_file() {
    local required_license="$1"
    local owner_name="$2"
    local year="$3"

    echo -n "Checking LICENSE file... "

    if [[ -f "LICENSE" ]]; then
        echo -e "${GREEN}exists${NC}"
        return
    fi

    echo -e "${YELLOW}creating${NC}"

    # Create LICENSE file with template
    create_license_template "${required_license}" "${owner_name}" "${year}" > LICENSE

    echo "  → Created LICENSE file with ${required_license} template"
    : $((FIX_COUNT++))
}

function create_license_template() {
    local license="$1"
    local owner="$2"
    local year="$3"

    # Path to canonical license templates
    local template_file="${SCRIPT_DIR}/licenses/templates/${license}.txt"

    if [[ -f "${template_file}" ]]; then
        # Use canonical template with substitutions
        sed -e "s/<year>/${year}/g" \
            -e "s/<copyright holders>/${owner}/g" \
            -e "s/(c) <year>/(c) ${year}/g" \
            -e "s/Copyright (c) <year>/Copyright © ${year}/g" \
            -e "s/\[yyyy\]/${year}/g" \
            -e "s/\[name of copyright owner\]/${owner}/g" \
            "${template_file}"
    else
        # Fallback for unknown licenses
        cat <<EOF
${license} License

Copyright © ${year} ${owner}

[License text for ${license}]
For full license text, see: https://spdx.org/licenses/${license}.html

WARNING: This is a placeholder. Please replace with the full ${license} license text.
EOF
    fi
}

function fix_notice_file() {
    local owner_name="$1"

    echo -n "Checking NOTICE file... "

    if [[ -f "NOTICE" ]]; then
        echo -e "${GREEN}exists${NC}"
        return
    fi

    echo -e "${YELLOW}creating${NC}"

    cat > NOTICE <<EOF
NOTICE

This software is developed and maintained by ${owner_name}.

For license information, see the LICENSE file.
EOF

    echo "  → Created NOTICE file"
    : $((FIX_COUNT++))
}

function fix_readme_license() {
    local required_license="$1"

    echo -n "Checking README.md license section... "

    if [[ ! -f "README.md" ]]; then
        echo -e "${YELLOW}creating${NC}"
        cat > README.md <<EOF
# Project

## License

This project is licensed under the ${required_license} License - see the [LICENSE](./LICENSE) file for details.
EOF
        echo "  → Created README.md with license section"
        : $((FIX_COUNT++))
        return
    fi

    # Check if license section exists (case-insensitive, flexible matching)
    # Match variations like "## License", "## §11. LICENSE", "## LICENSE", etc.
    if grep -qiE "^#{1,3} .*[Ll]icense" README.md; then
        echo -e "${GREEN}exists${NC}"
        return
    fi

    echo -e "${YELLOW}appending${NC}"

    # Append license section
    cat >> README.md <<EOF

## License

This project is licensed under the ${required_license} License - see the [LICENSE](./LICENSE) file for details.
EOF

    echo "  → Added license section to README.md"
    : $((FIX_COUNT++))
}

function fix_source_headers() {
    local required_license="$1"
    local owner_name="$2"
    local year="$3"

    echo "Fixing source file headers..."

    # Get all tracked source files (exclude data/config files like JSON, TOML, YAML, XML)
    local files
    files=$(git ls-files | grep -E '\.(sh|bash|py|js|ts|tsx|jsx|go|rs|c|cpp|h|hpp|java|rb|php|tex)$' | grep -v -E '\.(json|toml|yaml|yml|xml|md|txt)$' || true)

    if [[ -z "${files}" ]]; then
        echo "  No source files found"
        return
    fi

    local fixed=0

    while IFS= read -r file; do
        # Read first 20 lines
        local header
        header=$(head -n 20 "${file}")

        # Check for SPDX identifier
        local has_spdx=false
        local has_copyright=false

        if echo "${header}" | grep -q "SPDX-License-Identifier:.*${required_license}"; then
            has_spdx=true
        fi

        if echo "${header}" | grep -q "Copyright.*${owner_name}"; then
            has_copyright=true
        fi

        if [[ "${has_spdx}" == true ]] && [[ "${has_copyright}" == true ]]; then
            continue
        fi

        # Fix the file by prepending header
        inject_header "${file}" "${required_license}" "${owner_name}" "${year}"
        : $((fixed++))
        : $((FIX_COUNT++))
    done <<< "${files}"

    if [[ ${fixed} -gt 0 ]]; then
        echo -e "  ${GREEN}Fixed ${fixed} file(s)${NC}"
    else
        echo -e "  ${GREEN}All files have proper headers${NC}"
    fi
}

function inject_header() {
    local file="$1"
    local license="$2"
    local owner="$3"
    local year="$4"

    local ext="${file##*.}"
    local comment_start
    local comment_line
    local comment_end

    # Determine comment style
    case "${ext}" in
        sh|bash|py|rb)
            comment_line="#"
            ;;
        tex)
            comment_line="%"
            ;;
        js|ts|jsx|tsx|go|rs|c|cpp|h|hpp|java|php)
            comment_start="/*"
            comment_line=" *"
            comment_end=" */"
            ;;
        *)
            # Default to #
            comment_line="#"
            ;;
    esac

    # Create header
    local tmp_file
    tmp_file=$(mktemp)

    # Check if file has shebang
    local has_shebang=false
    if head -n 1 "${file}" | grep -q '^#!'; then
        has_shebang=true
    fi

    {
        # If shebang exists, preserve it first
        if [[ "${has_shebang}" == true ]]; then
            head -n 1 "${file}"
            echo ""
        fi

        # Write header comment
        if [[ -n "${comment_start:-}" ]]; then
            echo "${comment_start}"
        fi
        echo "${comment_line} SPDX-License-Identifier: ${license}"
        echo "${comment_line} Copyright © ${year} ${owner}"
        if [[ -n "${comment_end:-}" ]]; then
            echo "${comment_end}"
        fi
        echo ""

        # Write rest of file (skip shebang if we already wrote it)
        if [[ "${has_shebang}" == true ]]; then
            tail -n +2 "${file}"
        else
            cat "${file}"
        fi
    } > "${tmp_file}"

    mv "${tmp_file}" "${file}"

    echo "  → Fixed ${file}"
}
