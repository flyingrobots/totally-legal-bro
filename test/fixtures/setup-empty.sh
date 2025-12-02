#!/usr/bin/env bash
# Setup an empty test repository (fresh git init)

set -euo pipefail

REPO_DIR="$1"

mkdir -p "${REPO_DIR}"
cd "${REPO_DIR}"

# Initialize git
git init >/dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"

# Create ONLY a config file
cat > .legalbro.json <<'EOF'
{
  "requiredLicense": "MIT",
  "ownerName": "Empty Test"
}
EOF

git add .legalbro.json
git commit -m "Initial commit with config" >/dev/null 2>&1

echo "✓ Empty repository created at ${REPO_DIR}"
