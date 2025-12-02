#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>
set -euo pipefail

# Installer for totally-legal-bro into user space (~/.totally-legal-bro)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DEST:-${HOME}/.totally-legal-bro}"

# Validate destination is safe
case "${DEST}" in
    ""|"/"|"/usr"|"/usr/bin"|"/bin"|"/etc"|*".."*)
        echo "Refusing to install to unsafe DEST: ${DEST}" >&2
        exit 1
        ;;
esac

if [[ -e "${DEST}" ]]; then
    read -p "${DEST} exists. Overwrite? (y/N): " -r ans
    if [[ ! ${ans} =~ ^[Yy]$ ]]; then
        echo "Aborting install." >&2
        exit 1
    fi
fi

# Validate source assets (must be run from repo checkout)
for path in "${SCRIPT_DIR}/totally-legal-bro" "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/licenses"; do
    if [[ ! -e "${path}" ]]; then
        echo "Missing required file/dir: ${path}. Run from a repo checkout (not via curl|bash)." >&2
        exit 1
    fi
done

echo "Installing totally-legal-bro to ${DEST}"
mkdir -p "${DEST}"

# Copy core assets
cp -R "${SCRIPT_DIR}/totally-legal-bro" "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/licenses" "${DEST}/"

# Ensure executables
chmod +x "${DEST}/totally-legal-bro"
find "${DEST}/lib" -type f -name '*.sh' -exec chmod +x {} \;

ADD_LINE="export PATH=\"${DEST}:\$PATH\""

add_path_if_missing() {
    local rc_file="$1"
    if [[ ! -f "${rc_file}" ]]; then
        echo "RC file ${rc_file} not found; skipping PATH update for that shell" >&2
        return
    fi
    if ! grep -Fxq "${ADD_LINE}" "${rc_file}"; then
        echo "${ADD_LINE}" >> "${rc_file}"
        echo "Added PATH to ${rc_file}"
    fi
}

add_path_if_missing "${HOME}/.bashrc"
add_path_if_missing "${HOME}/.zshrc"

echo ""
echo "Done. Restart your shell or source the updated RC (e.g., 'source ~/.bashrc' or 'source ~/.zshrc')."
