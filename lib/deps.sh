#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Dependency scanning utilities

# Returns JSON with keys: status (pass|fail|warn|skip), manifests[], violations[], notes[]
function scan_dependencies() {
    local override_manifests="${1:-}"
    local manifests=()

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
        jq -n --argjson m "$(printf '%s\n' "${manifests[@]}" | jq -R . | jq -s .)" '{status:"warn", manifests:$m, violations:[], notes:["No dependencyPolicy defined; all licenses allowed"]}'
        return
    fi

    # Currently only npm enforcement implemented
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

                # Use license-checker to gather licenses
                local tmp_json
                tmp_json=$(mktemp)
                if ! npx --yes license-checker --json >"${tmp_json}" 2>/dev/null; then
                    notes+=("license-checker failed; ensure it is installable (npx license-checker)")
                    [[ "${status}" == "pass" ]] && status="warn"
                    rm -f "${tmp_json}"
                    continue
                fi

                # Iterate packages
                while IFS= read -r line; do
                    local pkg license
                    pkg="${line%%|*}"
                    license="${line##*|}"

                    if ! is_license_allowed "${license}"; then
                        violations+=("${pkg} (${license})")
                    fi
                done < <(jq -r 'to_entries[] | "\(.key)|\(.value.licenses)"' "${tmp_json}")

                rm -f "${tmp_json}"
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

    jq -n \
        --arg status "${status}" \
        --argjson m "$(printf '%s\n' "${manifests[@]}" | jq -R . | jq -s .)" \
        --argjson v "$(printf '%s\n' "${violations[@]}" | jq -R . | jq -s .)" \
        --argjson n "$(printf '%s\n' "${notes[@]}" | jq -R . | jq -s .)" \
        '{status:$status, manifests:$m, violations:$v, notes:$n}'
}

function detect_pm() {
    local file="$1"
    case "${file}" in
        *package.json) echo "npm" ;;
        *requirements.txt) echo "pip" ;;
        *Cargo.toml) echo "cargo" ;;
        *go.mod) echo "go" ;;
        *) echo "" ;;
    esac
}
