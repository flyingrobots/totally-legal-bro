#!/usr/bin/env bash
# Setup a partially compliant test repository

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
  "requiredLicense": "MIT",
  "ownerName": "Partial Corp"
}
EOF

# Create LICENSE
cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2024 Partial Corp

Permission is hereby granted, free of charge...
EOF

# Create README WITHOUT license section
cat > README.md <<'EOF'
# Partial Project

This project is missing some compliance stuff.

## Features

- Feature 1
- Feature 2
EOF

# NO NOTICE file (missing)

# Create mix of files - some with headers, some without

# File WITH correct header
cat > good.py <<'EOF'
# SPDX-License-Identifier: MIT
# Copyright (c) 2024 Partial Corp

def good_function():
    return "I have a header!"
EOF

# File WITHOUT header
cat > bad.py <<'EOF'
def bad_function():
    return "I need a header!"
EOF

# File WITH shebang but NO header
cat > tool.sh <<'EOF'
#!/bin/bash
echo "I have shebang but no header"
EOF
chmod +x tool.sh

# JavaScript WITHOUT header
cat > app.js <<'EOF'
console.log("No header here");
EOF

# File WITH header
cat > utils.js <<'EOF'
/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2024 Partial Corp
 */

export function util() {
    return "utility";
}
EOF

# Commit everything
git add .
git commit -m "Partial compliance" >/dev/null 2>&1

echo "✓ Partially compliant repository created at ${REPO_DIR}"
