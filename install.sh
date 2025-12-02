#!/usr/bin/env bash
set -euo pipefail

# Installer for totally-legal-bro into user space (~/.totally-legal-bro)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DEST:-${HOME}/.totally-legal-bro}"

echo "Installing totally-legal-bro to ${DEST}"
mkdir -p "${DEST}"

# Copy core assets
cp -R "${SCRIPT_DIR}/totally-legal-bro" "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/licenses" "${DEST}/"

# Ensure executables
chmod +x "${DEST}/totally-legal-bro"
find "${DEST}/lib" -type f -name '*.sh' -exec chmod +x {} \;

ADD_LINE="export PATH=\"${DEST}:$PATH\""

add_path_if_missing() {
    local rc_file="$1"
    [[ -f "${rc_file}" ]] || return
    if ! grep -Fq "${DEST}" "${rc_file}"; then
        echo "${ADD_LINE}" >> "${rc_file}"
        echo "Added PATH to ${rc_file}"
    fi
}

add_path_if_missing "${HOME}/.bashrc"
add_path_if_missing "${HOME}/.zshrc"

echo ""
echo "Done. Restart your shell or run: ${ADD_LINE}"
