#!/usr/bin/env bats

load test_helper.bash

setup() {
  REPO=$(setup_test_repo)
  cd "$REPO"
}

@test "--version prints version" {
  run_tlb --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^0\.1\.0$ ]]
}

@test "--config uses alternate config path" {
  cat > alt.json <<'EOF'
{
  "requiredLicense": "Apache-2.0",
  "ownerName": "Alt Owner",
  "dependencyPolicy": []
}
EOF
  touch LICENSE

  run_tlb --config alt.json check
  # Should complain about README/license headers, not missing config
  [ "$status" -ne 0 ]
  assert_output_not_contains "Config file .legalbro.json not found"
}

@test "check --json emits JSON" {
  create_config "MIT" "Tester"
  touch LICENSE
  run_tlb --json check
  [ "$status" -ne 0 ]
  echo "$output" | jq -e '.license.status' >/dev/null
}

@test "check --manifests override accepted" {
  create_config "MIT" "Tester"
  touch LICENSE README.md
  run_tlb check --manifests package.json
  [ "$status" -ne 0 ]
  assert_output_contains "Dependencies"
}

@test "fix --no-headers leaves source untouched" {
  create_config "MIT" "Tester"
  echo "console.log('hi');" > app.js
  git add app.js .legalbro.json
  run_tlb fix --no-headers
  [ "$status" -eq 0 ]
  # header should not be added
  if grep -q "SPDX-License-Identifier" app.js; then
    echo "unexpected header injected"
    return 1
  fi
}

@test "fix --headers-only injects headers but not LICENSE" {
  create_config "MIT" "Tester"
  echo "console.log('hi');" > app.js
  git add app.js .legalbro.json
  run_tlb fix --headers-only
  [ "$status" -eq 0 ]
  grep -q "SPDX-License-Identifier: MIT" app.js
  [ ! -f LICENSE ]
}

@test "headerTemplate is applied" {
  cat > .legalbro.json <<'EOF'
{
  "requiredLicense": "MIT",
  "ownerName": "Tester",
  "headerTemplate": "// License: {{LICENSE}} | Owner: {{OWNER}} | Year: {{YEAR}}"
}
EOF
  git add .legalbro.json
  echo "console.log('hi');" > app.js
  git add app.js
  run_tlb fix --headers-only
  [ "$status" -eq 0 ]
  grep -q "License: MIT | Owner: Tester" app.js
}
