# Test Fixture Scenarios

## Edge Cases We Need to Cover

### Repo States
1. **Empty Repo** - Fresh `git init`, no files at all
2. **Minimal Repo** - Just a README, no config
3. **Fully Compliant** - LICENSE, NOTICE, README, all headers present
4. **Partially Compliant** - Some files have headers, some don't
5. **Wrong License** - Has LICENSE but wrong SPDX
6. **No Config** - No `.legalbro.json` file

### File Header Edge Cases
1. **Files with shebangs** - `#!/usr/bin/env python3` should stay first
2. **Files with existing wrong headers** - Should we overwrite or skip?
3. **Files without headers** - Should get headers injected
4. **Files with correct headers** - Should not be modified
5. **Binary files** - Should be ignored (images, PDFs, etc.)
6. **Non-source files** - .txt, .md, .json should be ignored

### .gitignore Edge Cases
1. **Ignored source files** - Files matching .gitignore patterns should NOT get headers
2. **Ignored directories** - node_modules/, dist/, etc.
3. **Tracked files** - Only `git ls-files` output should be checked

### Comment Style Edge Cases
1. **Bash/Python** - `# SPDX-License-Identifier`
2. **JavaScript/TypeScript** - `/* SPDX-License-Identifier */`
3. **Go/Rust/C** - `/* SPDX-License-Identifier */`
4. **Ruby** - `# SPDX-License-Identifier`
5. **PHP** - `/* SPDX-License-Identifier */`

### README Edge Cases
1. **No README** - Should create one with license section
2. **README without license section** - Should append
3. **README with license section** - Should not modify
4. **README.md vs README** - Only check README.md

### Dependency Edge Cases
1. **No package.json** - Should skip dependency check
2. **package.json with dependencies** - Should scan (future: use license-checker)
3. **No dependencyPolicy in config** - Should allow all licenses
4. **dependencyPolicy defined** - Should enforce

## Fixture Scripts to Create

### 1. `fixtures/setup-empty.sh`
- Fresh git init
- No files
- Should fail all checks

### 2. `fixtures/setup-compliant.sh`
- LICENSE with Apache-2.0
- NOTICE file
- README.md with license section
- Multiple source files with correct headers
- .gitignore with some patterns
- All files committed

### 3. `fixtures/setup-partial.sh`
- LICENSE exists
- No NOTICE
- README exists but no license section
- Mix of files: some with headers, some without
- Some files with shebangs
- .gitignore present

### 4. `fixtures/setup-gitignore-test.sh`
- .gitignore with patterns
- Source files in ignored directories (shouldn't get headers)
- Source files in tracked directories (should get headers)
- Ignored source file at root (shouldn't get headers)

### 5. `fixtures/setup-wrong-license.sh`
- LICENSE with MIT
- Config requires Apache-2.0
- Should fail check

### 6. `fixtures/setup-multi-language.sh`
- .py files (# comments)
- .js files (/* */ comments)
- .sh files with shebangs
- .go files
- Mix of header states
