#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Init command: Set up config, git hooks, and CI templates

function cmd_init() {
    echo -e "${BLUE}🤙 Initializing totally-legal-bro...${NC}"
    echo ""

    # Check if already initialized
    if config_exists; then
        echo -e "${YELLOW}Warning: ${CONFIG_FILE} already exists${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborting."
            exit 0
        fi
    fi

    # Prompt for required config
    echo "Let's set up your config..."
    echo ""

    local required_license
    local owner_name
    local setup_hooks="y"
    local setup_ci="y"

    read -r -p "Required License (SPDX ID, e.g., MIT, Apache-2.0): " required_license
    while [[ -z "${required_license}" ]]; do
        echo -e "${RED}License is required${NC}"
        read -r -p "Required License (SPDX ID, e.g., MIT, Apache-2.0): " required_license
    done

    read -r -p "Owner Name (e.g., Your Name or Company): " owner_name
    while [[ -z "${owner_name}" ]]; do
        echo -e "${RED}Owner name is required${NC}"
        read -r -p "Owner Name (e.g., Your Name or Company): " owner_name
    done

    # Optional: dependency policy
    echo ""
    echo "Dependency Policy (optional):"
    echo "Enter approved SPDX licenses for dependencies, one per line."
    echo "Leave blank and press Enter when done."

    local dep_licenses=()
    while true; do
        read -r -p "License (or blank to finish): " license
        if [[ -z "${license}" ]]; then
            break
        fi
        dep_licenses+=("${license}")
    done

    # Create config file
    echo ""
    echo -e "${BLUE}Creating ${CONFIG_FILE}...${NC}"

    local dep_policy_json="[]"
    if [[ ${#dep_licenses[@]} -gt 0 ]]; then
        dep_policy_json=$(printf '%s\n' "${dep_licenses[@]}" | jq -R . | jq -s .)
    fi

    jq -n \
        --arg license "${required_license}" \
        --arg owner "${owner_name}" \
        --argjson policy "${dep_policy_json}" \
        '{
            requiredLicense: $license,
            ownerName: $owner,
            dependencyPolicy: $policy
        }' > "${CONFIG_FILE}"

    echo -e "${GREEN}✓ Created ${CONFIG_FILE}${NC}"

    # Set up git hooks
    echo ""
    read -p "Set up git pre-commit hook? (Y/n): " -n 1 -r setup_hooks
    echo
    if [[ ! $setup_hooks =~ ^[Nn]$ ]]; then
        setup_git_hook
    fi

    # Set up CI
    echo ""
    read -p "Generate GitHub Actions CI workflow? (Y/n): " -n 1 -r setup_ci
    echo
    if [[ ! $setup_ci =~ ^[Nn]$ ]]; then
        setup_github_ci
    fi

    echo ""
    echo -e "${GREEN}🎉 All set! Run 'totally-legal-bro check' to validate your repo${NC}"
}

function setup_git_hook() {
    local hooks_dir=".git/hooks"
    local hook_file="${hooks_dir}/pre-commit"

    if [[ ! -d ".git" ]]; then
        echo -e "${YELLOW}Warning: Not a git repository, skipping hook setup${NC}"
        return
    fi

    mkdir -p "${hooks_dir}"

    # Check if hook already exists
    if [[ -f "${hook_file}" ]]; then
        # Check if our hook is already in there
        if grep -q "totally-legal-bro check" "${hook_file}"; then
            echo -e "${YELLOW}Git hook already configured${NC}"
            return
        fi

        # Append to existing hook
        echo -e "${YELLOW}Appending to existing pre-commit hook${NC}"
        cat >> "${hook_file}" <<'EOF'

# totally-legal-bro check
if command -v totally-legal-bro &> /dev/null; then
    totally-legal-bro check || exit 1
else
    echo "Warning: totally-legal-bro not in PATH, skipping license check"
fi
EOF
    else
        # Create new hook
        cat > "${hook_file}" <<'EOF'
#!/usr/bin/env bash
set -e

# totally-legal-bro pre-commit check
if command -v totally-legal-bro &> /dev/null; then
    totally-legal-bro check || exit 1
else
    echo "Warning: totally-legal-bro not in PATH, skipping license check"
fi
EOF
        chmod +x "${hook_file}"
    fi

    echo -e "${GREEN}✓ Git pre-commit hook installed${NC}"
}

function setup_github_ci() {
    local workflow_dir=".github/workflows"
    local workflow_file="${workflow_dir}/legal-bro.yml"

    mkdir -p "${workflow_dir}"

    if [[ -f "${workflow_file}" ]]; then
        echo -e "${YELLOW}Warning: ${workflow_file} already exists, skipping${NC}"
        return
    fi

    cat > "${workflow_file}" <<'EOF'
name: Legal Compliance Check

on:
  pull_request:
  push:
    branches: [main, master]

jobs:
  legal-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq

      - name: Add totally-legal-bro to PATH
        run: echo "${{ github.workspace }}" >> $GITHUB_PATH

      - name: Run legal compliance check
        run: totally-legal-bro check
EOF

    echo -e "${GREEN}✓ Created GitHub Actions workflow: ${workflow_file}${NC}"
}
