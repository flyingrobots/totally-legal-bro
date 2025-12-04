#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# SPDX-License-Identifier: Apache-2.0
# Dependency scanning utilities

# Returns JSON with keys: status (pass|fail|warn|skip), manifests[], violations[], notes[]
function scan_dependencies() {
    local override_manifests="${1:-}"
    local manifests=()

    if ! declare -F get_dependency_policy >/dev/null 2>&1; then
        echo "get_dependency_policy is not defined"
        return 1
    fi

    if [[ -n "${override_manifests}" ]]; then
        IFS=',' read -r -a user_manifests <<< "${override_manifests}"
        for m in "${user_manifests[@]}"; do
            local pm
            pm=$(detect_pm "${m}")
            [[ -n "${pm}" ]] && manifests+=("${m}:${pm}")
        done
    else
        [[ -f "package.json" ]] && manifests+=("package.json:npm")
        [[ -f "requirements.txt" ]] && manifests+=("requirements.txt:pip")
        [[ -f "Cargo.toml" ]] && manifests+=("Cargo.toml:cargo")
        [[ -f "go.mod" ]] && manifests+=("go.mod:go")
    fi

    if [[ ${#manifests[@]} -eq 0 ]]; then
        jq -n '{status:"skip", manifests:[], violations:[], notes:["No dependency manifests found"]}'
        return
    fi

    local policy
    policy=$(get_dependency_policy)

    if [[ -z "${policy}" ]]; then
        local m_json
        m_json=$(printf '%s\0' "${manifests[@]}" | jq -R -s 'split("\u0000")[:-1]')
        jq -n --argjson m "${m_json}" '{status:"warn", manifests:$m, violations:[], notes:["No dependencyPolicy defined; all licenses allowed"]}'
        return
    fi

    # Currently only npm enforcement implemented using POSIX+jq
    local violations=()
    local notes=()
    local status="pass"

    for manifest_info in "${manifests[@]}"; do
        local manifest="${manifest_info%%:*}"
        local pm="${manifest_info##*:}"

        case "${pm}" in
            npm)
                if [[ ! -d "node_modules" ]]; then
                    notes+=("node_modules missing; run npm install before check")
                    [[ "${status}" == "pass" ]] && status="warn"
                    continue
                fi

                # Gather licenses by scanning node_modules package.json files
                # Traverse full npm tree (no depth cap) to catch transitive deps
                # Use find -print0 and xargs -0 for safe handling of filenames with spaces
                # Invoke jq once per package.json to get pkg and license in one go
                local all_deps_json
                all_deps_json=$(find node_modules -type f -name package.json -print0 | \
                                xargs -0 jq -c '{pkg: (.name + "@" + (.version // "")), license: (.license // "UNKNOWN")}')

                while IFS= read -r json_line; do
                    local pkg license
                    # Parse pkg and license from the pre-formatted JSON line
                    pkg=$(echo "${json_line}" | jq -r '.pkg' 2>/dev/null || echo "unknown")
                    license=$(echo "${json_line}" | jq -r '.license' 2>/dev/null || echo "UNKNOWN")

                    if ! is_license_allowed "${license}"; then
                        violations+=("${pkg} (${license})")
                    fi
                done <<< "${all_deps_json}"
                ;;
            *)
                notes+=("${pm} scanning TODO")
                [[ "${status}" == "pass" ]] && status="warn"
                ;;
        esac
    done

    if [[ ${#violations[@]} -gt 0 ]]; then
        status="fail"
    fi

    local m_json v_json n_json
    m_json=$(array_to_json "${manifests[@]}")
    v_json=$(array_to_json "${violations[@]}")
    n_json=$(array_to_json "${notes[@]}")

    jq -n \
        --arg status "${status}" \
        --argjson m "${m_json}" \
        --argjson v "${v_json}" \
        --argjson n "${n_json}" \
        '{status:$status, manifests:$m, violations:$v, notes:$n}'
}

function detect_pm() {
    local file="$1"
    # Returns empty string for unknown manifests (silent by default); pass a second arg to emit a warning to stderr.
    case "${file}" in
        *package.json) echo "npm" ;;
        *requirements.txt) echo "pip" ;;
        *Cargo.toml) echo "cargo" ;;
        *go.mod) echo "go" ;;
        *)
            if [[ -n "${2:-}" ]]; then
                echo "WARN: Unrecognized manifest '${file}'" >&2
            fi
            echo ""
            ;;
    esac
}

function array_to_json() {
    if [[ $# -eq 0 ]]; then
        echo '[]'
        return
    fi
    printf '%s\n' "$@" | jq -R . | jq -s .
}
