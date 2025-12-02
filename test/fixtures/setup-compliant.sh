#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright © 2025 James Ross <james@flyingrobots.dev>

# Setup a fully compliant test repository

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
  "ownerName": "Test Owner",
  "dependencyPolicy": ["Apache-2.0", "MIT"]
}
EOF

# Create LICENSE
cat > LICENSE <<'EOF'
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright 2024 Test Owner

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
EOF

# Create NOTICE
cat > NOTICE <<'EOF'
NOTICE

This software is developed and maintained by Test Owner.

For license information, see the LICENSE file.
EOF

# Create README
cat > README.md <<'EOF'
# Test Project

This is a test project for totally-legal-bro.

## License

This project is licensed under the Apache-2.0 License - see the LICENSE file for details.
EOF

# Create .gitignore
cat > .gitignore <<'EOF'
node_modules/
dist/
*.log
.env
ignored.py
EOF

# Create source files with proper headers

# Python file with header
cat > main.py <<'EOF'
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2024 Test Owner

def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF

# JavaScript file with header
cat > app.js <<'EOF'
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (c) 2024 Test Owner
 */

function main() {
    console.log("Hello, World!");
}

main();
EOF

# Bash script with shebang and header
cat > script.sh <<'EOF'
#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2024 Test Owner

echo "Hello, World!"
EOF
chmod +x script.sh

# Go file with header
cat > server.go <<'EOF'
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (c) 2024 Test Owner
 */

package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
EOF

# LaTeX file with header (uses % for comments)
cat > document.tex <<'EOF'
% SPDX-License-Identifier: Apache-2.0
% Copyright (c) 2024 Test Owner

\documentclass{article}
\begin{document}
Hello, World!
\end{document}
EOF

# JSON files (should be IGNORED - no headers in JSON)
cat > package.json <<'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "license": "Apache-2.0"
}
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020"
  }
}
EOF

# TOML file (Cargo.toml - should be IGNORED, no headers in TOML)
cat > Cargo.toml <<'EOF'
[package]
name = "test"
version = "0.1.0"
license = "Apache-2.0"
EOF

# Commit everything
git add .
git commit -m "Initial compliant commit" >/dev/null 2>&1

echo "✓ Compliant repository created at ${REPO_DIR}"
