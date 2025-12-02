#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Setup repository to test .gitignore handling

set -euo pipefail

REPO_DIR="$1"

mkdir -p "${REPO_DIR}"
cd "${REPO_DIR}"

# Initialize git
git init >/dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"

# Create config
cat > .legalbro.json <<'EOF'
{
  "requiredLicense": "Apache-2.0",
  "ownerName": "Ignore Test"
}
EOF

# Create LICENSE
cat > LICENSE <<'EOF'
Apache License
Version 2.0

Copyright 2024 Ignore Test
EOF

# Create README
cat > README.md <<'EOF'
# Gitignore Test

## License
Apache-2.0
EOF

# Create .gitignore
cat > .gitignore <<'EOF'
node_modules/
dist/
*.log
secret.py
build/
EOF

# Create a TRACKED file (should get header)
cat > tracked.py <<'EOF'
print("I am tracked and should get a header")
EOF

# Create an IGNORED file at root (should NOT get header)
cat > secret.py <<'EOF'
print("I am ignored and should NOT get a header")
EOF

# Create ignored directory with files
mkdir -p node_modules
cat > node_modules/library.js <<'EOF'
// I am in node_modules and should be ignored
module.exports = {};
EOF

# Create tracked directory with files
mkdir -p src
cat > src/main.py <<'EOF'
print("I am in tracked src/ and should get a header")
EOF

mkdir -p build
cat > build/output.js <<'EOF'
// I am in build/ and should be ignored
console.log("build artifact");
EOF

# Commit only tracked files
git add .
git commit -m "Gitignore test" >/dev/null 2>&1

echo "✓ Gitignore test repository created at ${REPO_DIR}"
echo "  Tracked files: tracked.py, src/main.py"
echo "  Ignored files: secret.py, node_modules/*, build/*"
