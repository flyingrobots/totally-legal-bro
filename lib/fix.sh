#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Fix command: Auto-repair missing headers and files

declare -i FIX_COUNT=0
: "${GIT_CMD:=git}"

# Guard against missing or invalid LIB_DIR
: "${LIB_DIR:?LIB_DIR must be set to the directory containing utils.sh}"
if [[ ! -f "${LIB_DIR}/utils.sh" ]]; then
    echo "ERROR: ${LIB_DIR}/utils.sh not found" >&2
    exit 1
fi

source "${LIB_DIR}/utils.sh"

function cmd_fix() {
    echo -e "${BLUE}🔧 Auto-fixing legal compliance issues...${NC}"
    echo ""

    local skip_headers=0
    local headers_only=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-headers)
                skip_headers=1; shift ;;
            --headers-only)
                headers_only=1; shift ;;
            *) shift ;;
        esac
    done

    if ! validate_config; then
        exit 1
    fi

    local required_license owner_name current_year header_template
    required_license=$(get_config "requiredLicense")
    owner_name=$(get_config "ownerName")
    header_template=$(get_config "headerTemplate")
    current_year=$(date +%Y)

    echo "Config: License=${required_license}, Owner=${owner_name}"
    echo ""

    if [[ ${headers_only} -eq 0 ]]; then
        fix_license_file "${required_license}" "${owner_name}" "${current_year}"
        fix_notice_file "${owner_name}"
        fix_readme_license "${required_license}"
    fi

    if [[ ${skip_headers} -eq 0 ]]; then
        fix_source_headers "${required_license}" "${owner_name}" "${current_year}" "${header_template}"
    fi

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
        # Check if LICENSE contains the correct license type (same logic as check.sh)
        local license_base escaped_license_base
        license_base=$(echo "${required_license}" | sed 's/-.*//; s/\..*//')
        # Escape regex metacharacters in license_base for safe grep
        escaped_license_base=$(printf '%s\n' "${license_base}" | sed 's/[.[\*^$()+?{|]/\\&/g')

        if ! grep -qiE "\\b${escaped_license_base}\\b" LICENSE; then
            echo -e "${YELLOW}regenerating (wrong license type)${NC}"
            create_license_template "${required_license}" "${owner_name}" "${year}" > LICENSE
            echo "  → Regenerated LICENSE file with ${required_license} template"
            : $((FIX_COUNT++))
            return
        fi

        # Check for placeholder text (same patterns as check.sh)
        local placeholder_patterns=(
            '\[Full.*text.*here\]'
            '\[.*license.*text.*\]'
            'TODO'
            'PLACEHOLDER'
            '\[yyyy\]'
            '\[name of copyright owner\]'
            '\[fullname\]'
        )

        local has_placeholder=false
        for pattern in "${placeholder_patterns[@]}"; do
            if grep -qiE "${pattern}" LICENSE; then
                has_placeholder=true
                break
            fi
        done

        if [[ "${has_placeholder}" == true ]]; then
            echo -e "${YELLOW}regenerating (placeholder detected)${NC}"
            create_license_template "${required_license}" "${owner_name}" "${year}" > LICENSE
            echo "  → Regenerated LICENSE file with ${required_license} template"
            : $((FIX_COUNT++))
            return
        fi

        echo -e "${GREEN}exists${NC}"
        return
    fi

    echo -e "${YELLOW}creating${NC}"
    create_license_template "${required_license}" "${owner_name}" "${year}" > LICENSE
    echo "  → Created LICENSE file with ${required_license} template"
    : $((FIX_COUNT++))
}

function create_license_template() {
    local license="$1"
    local owner="$2"
    local year="$3"

    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        echo "ERROR: SCRIPT_DIR not set; cannot find license templates" >&2
        return 1
    fi

    local template_file="${SCRIPT_DIR}/licenses/templates/${license}.txt"

    # Escape replacement values for sed (/ & \)
    local escaped_owner escaped_year
    escaped_owner=$(printf '%s\n' "${owner}" | sed -e 's/[\\\\/&]/\\&/g')
    escaped_year=$(printf '%s\n' "${year}" | sed -e 's/[\\\\/&]/\\&/g')

    if [[ -f "${template_file}" ]]; then
        sed -e "s/<year>/${escaped_year}/g" \
            -e "s/<copyright holders>/${escaped_owner}/g" \
            -e "s/(c) <year>/(c) ${escaped_year}/g" \
            -e "s/Copyright (c) <year>/Copyright © ${escaped_year}/g" \
            -e "s/\\[yyyy\\]/${escaped_year}/g" \
            -e "s/\\[name of copyright owner\\]/${escaped_owner}/g" \
            "${template_file}"
    else
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

    if grep -qiE "^#{1,3} .*[Ll]icense" README.md; then
        if ! grep -q "${required_license}" README.md; then
            echo -e "${YELLOW}rewriting${NC}"
            rewrite_license_section "${required_license}"
            echo "  → Updated README license section to ${required_license}"
            : $((FIX_COUNT++))
            return
        fi
        echo -e "${GREEN}exists${NC}"
        return
    fi

    echo -e "${YELLOW}appending${NC}"
    cat >> README.md <<EOF

## License

This project is licensed under the ${required_license} License - see the [LICENSE](./LICENSE) file for details.
EOF
    echo "  → Added license section to README.md"
    : $((FIX_COUNT++))
}

function rewrite_license_section() {
    local required_license="$1"
    local tmp
    tmp=$(mktemp)

    awk -v lic="${required_license}" '
    BEGIN{in_section=0; replaced=0}
    /^#{1,3} [Ll]icense/ {
        if(!replaced){
            print "## License"; print ""; print "This project is licensed under the " lic " License - see the [LICENSE](./LICENSE) file for details."; print "";
            replaced=1; in_section=1; next
        }
    }
    in_section && /^#/ {in_section=0}
    !in_section {print}
    ' README.md > "${tmp}" && mv "${tmp}" README.md
}

function fix_source_headers() {
    local required_license="$1"
    local owner_name="$2"
    local year="$3"
    local header_template="$4"

    echo "Fixing source file headers..."

    local files
    files=$(get_source_files)

    if [[ -z "${files}" ]]; then
        echo "  No source files found"
        return
    fi

    local fixed=0

    while IFS= read -r file; do
        local header
        header=$(head -n 20 "${file}")

        local has_spdx=false
        local has_copyright=false

        if echo "${header}" | grep -E -q "SPDX-License-Identifier:.*${required_license}"; then
            has_spdx=true
        fi

        # Check for copyright with symbol (same pattern as check.sh)
        if echo "${header}" | grep -E -q "Copyright.*(©|\(c\)).*${owner_name}"; then
            has_copyright=true
        fi

        if [[ "${has_spdx}" == true ]] && [[ "${has_copyright}" == true ]]; then
            continue
        fi

        inject_header "${file}" "${required_license}" "${owner_name}" "${year}" "${header_template}"
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
    local header_template="$5"

    local ext="${file##*.}"
    local comment_start
    local comment_line
    local comment_end

    case "${ext}" in
        sh|bash|py|rb) comment_line="#" ;;
        tex) comment_line="%" ;;
        js|ts|jsx|tsx|go|rs|c|cpp|h|hpp|java|php)
            comment_start="/*"; comment_line=" *"; comment_end=" */" ;;
        *) comment_line="#" ;;
    esac

    local tmp_file
    tmp_file=$(mktemp)

    local has_shebang=false
    if head -n 1 "${file}" | grep -q '^#!'; then
        has_shebang=true
    fi

    # Create a cleaned version of the file without existing SPDX/Copyright header lines
    local cleaned_file
    cleaned_file=$(mktemp)

    if [[ "${has_shebang}" == true ]]; then
        # Keep shebang, skip old header lines, keep rest
        head -n 1 "${file}" > "${cleaned_file}"
        tail -n +2 "${file}" | sed -E '/^[#%\/\*[:space:]]*(SPDX-License-Identifier|Copyright)/d; /^[[:space:]]*\*\/[[:space:]]*$/d; /^[[:space:]]*\/\*[[:space:]]*$/d' >> "${cleaned_file}"
    else
        # No shebang, just remove header lines
        sed -E '/^[#%\/\*[:space:]]*(SPDX-License-Identifier|Copyright)/d; /^[[:space:]]*\*\/[[:space:]]*$/d; /^[[:space:]]*\/\*[[:space:]]*$/d' "${file}" > "${cleaned_file}"
    fi

    {
        if [[ "${has_shebang}" == true ]]; then
            head -n 1 "${file}"; echo ""
        fi

        if [[ -n "${header_template}" ]]; then
            local escaped_license escaped_owner escaped_year
            escaped_license=$(printf '%s\n' "${license}" | sed -e 's/[\\\\/&]/\\&/g')
            escaped_owner=$(printf '%s\n' "${owner}" | sed -e 's/[\\\\/&]/\\&/g')
            escaped_year=$(printf '%s\n' "${year}" | sed -e 's/[\\\\/&]/\\&/g')

            printf '%s\n' "${header_template}" | \
                sed -e "s/{{LICENSE}}/${escaped_license}/g" \
                    -e "s/{{OWNER}}/${escaped_owner}/g" \
                    -e "s/{{YEAR}}/${escaped_year}/g"
            echo ""
        else
            [[ -n "${comment_start:-}" ]] && echo "${comment_start}"
            echo "${comment_line} SPDX-License-Identifier: ${license}"
            echo "${comment_line} Copyright © ${year} ${owner}"
            [[ -n "${comment_end:-}" ]] && echo "${comment_end}"
            echo ""
        fi

        if [[ "${has_shebang}" == true ]]; then
            tail -n +2 "${cleaned_file}"
        else
            cat "${cleaned_file}"
        fi
    } > "${tmp_file}"

    rm -f "${cleaned_file}"
    mv "${tmp_file}" "${file}"
    echo "  → Fixed ${file}"
}
