#!/usr/bin/env bats

load test_helper.bash

setup() {
  REPO=$(setup_test_repo)
  cd "$REPO"
}

@test "deps: errors if get_dependency_policy missing" {
  cat > minimal.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source /app/lib/deps.sh
unset -f get_dependency_policy || true
scan_dependencies
EOF
  run bash minimal.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"get_dependency_policy is not defined"* ]]
}

@test "deps: npm license scan flags disallowed license from node_modules package.json" {
  create_config "MIT" "Tester"
  mkdir -p node_modules/badpkg
  cat > node_modules/badpkg/package.json <<'EOF'
{
  "name": "badpkg",
  "version": "1.0.0",
  "license": "GPL-3.0"
}
EOF

  # Use dependencyPolicy to only allow MIT
  cat > .legalbro.json <<'EOF'
{
  "requiredLicense": "MIT",
  "ownerName": "Tester",
  "dependencyPolicy": ["MIT"]
}
EOF

  run totally-legal-bro check --manifests package.json
  [ "$status" -ne 0 ]
  assert_output_contains "badpkg@1.0.0 (GPL-3.0)"
}

@test "deps: npm scan catches deep transitive license violations" {
  create_config "MIT" "Tester"
  mkdir -p node_modules/parent/node_modules/child/node_modules/deep
  cat > node_modules/parent/node_modules/child/node_modules/deep/package.json <<'EOF'
{
  "name": "deep-bad",
  "version": "2.0.0",
  "license": "GPL-3.0"
}
EOF

  run totally-legal-bro check --manifests package.json
  [ "$status" -ne 0 ]
  assert_output_contains "deep-bad@2.0.0 (GPL-3.0)"
}

@test "deps: warns when node_modules missing" {
  create_config "MIT" "Tester"
  run totally-legal-bro check --manifests package.json
  [ "$status" -ne 0 ]
  assert_output_contains "node_modules missing"
}
