<div align="center" style="font-size:2rem; font-weight:bold;">

# ⚖️ THE TOTALLY-LEGAL-BRO ACT OF 2025

*A Public Statute for the Governance of Software Licensing Compliance*

</div>

---

## PREAMBLE

**WHEREAS**, developers routinely forget to add LICENSE files;
**AND WHEREAS**, the insertion of SPDX headers is a burden upon mankind;
**AND WHEREAS**, unlicensed dependencies are the leading cause of emotional distress in DevOps teams;

**THEREFORE**, let it be enacted that:

> **totally-legal-bro SHALL keep your repo totally legal, bro.**

---

## §1. DEFINITIONS

1. **"The Bro"** refers to the `totally-legal-bro` utility, its shell scripts, configurations, and any spiritually adjacent vibes.
2. **"Subject Repository"** refers to any Git repository that dares exist without proper licensing discipline.
3. **"SPDX Header"** means the legally mandated incantation required to appease the Open Source Elders.
4. **"Fix Mode"** refers to the miraculous act wherein The Bro amends the Subject Repository's sins.

---

### §1.1 Install & Run Anywhere

1. `git clone https://github.com/flyingrobots/totally-legal-bro.git && cd totally-legal-bro`
2. `./install.sh` (copies to `~/.totally-legal-bro`, ensures exec bits, adds to PATH)
3. Restart your shell or `export PATH="$HOME/.totally-legal-bro:$PATH"`
4. In any git repo: `totally-legal-bro init` (creates `.legalbro.json`)
5. `totally-legal-bro fix && totally-legal-bro check`

---

## §2. POWERS AND DUTIES OF THE BRO

### §2.1 Initialization Procedure

```bash
totally-legal-bro init
```

Upon execution of this sacred rite, The Bro **SHALL**:
- Generate `.legalbro.json`
- Establish Git hooks with extreme prejudice
- Create CI workflows to enforce purity
- Emit at least one chill vibe (🤙)

---

### §2.2 Corrective Measures ("Fix Mode")

```bash
totally-legal-bro fix
```

The Bro **SHALL**:
- Conjure `LICENSE` and `NOTICE` files *ex nihilo*
- Inject SPDX headers into all tracked files, respecting local dialects (e.g., `#`, `//`, `/* */`)
- Amend `README.md` to include legal disclosures
- Forgive the developer for their negligence (one-time use only)

---

### §2.3 Verification of Legal Integrity

```bash
totally-legal-bro check
```

The Bro **SHALL** conduct an inquiry including:
- Authentication of `LICENSE` contents
- Examination of source file headers
- Verification of `README` license attestations
- Audit of dependency compliance vis-à-vis §3 (Dependency Policy)

Should any violation be found, The Bro **SHALL** throw a fatal error, accompanied by light emotional judgment.

---

### §2.4 Reporting Requirements

```bash
totally-legal-bro report
```

The Bro **SHALL** provide a comprehensive dossier including:
- File-by-file compliance status
- Dependency license matrix
- Count of sins corrected
- A vibe score (Beta)

---

## CLI Flags

- `--version` — print version
- `--config <path>` — use alternate `.legalbro.json`
- `--json` — JSON output for `check`/`report`
- `--verbose` / `--quiet` — adjust verbosity (quiet minimizes output)

Command-specific:
- `fix --no-headers` — skip header injection
- `fix --headers-only` — only inject headers
- `check --manifests <paths>` — comma-separated manifest paths to scan instead of auto-detect

## §3. DEPENDENCY LICENSE COMPLIANCE

The Subject Repository **SHALL NOT** import any dependency with a license outside the approved allowlist unless the developer wishes to incur:
- Moral shame
- Technical debt
- Or both

### Dependency License Scanning (current state)

- **npm**: placeholder enforcement. Requires `node_modules` to exist. Recommended tooling: `npx license-checker --json --production` (installed on demand via npx) to enumerate licenses.
- **pip / go / cargo**: scanning is TODO.
- When scanning is unavailable (missing `node_modules` or tool failure), checks emit WARN (not FAIL) until tooling is added.

---

## §4. CONFIGURATION

The Subject Repository **SHALL** maintain `.legalbro.json` at its root:

```json
{
  "requiredLicense": "Apache-2.0",
  "ownerName": "Your Name <you@example.com>",
  "headerTemplate": "/*\\n * SPDX-License-Identifier: {{LICENSE}}\\n * Copyright (c) {{YEAR}} {{OWNER}}\\n */",
  "dependencyPolicy": ["MIT", "Apache-2.0", "BSD-3-Clause"]
}
```

| Field | Required | Purpose |
|-------|----------|---------|
| `requiredLicense` | ✅ | SPDX license identifier (e.g., `MIT`, `Apache-2.0`) |
| `ownerName` | ✅ | Copyright holder name and/or email |
| `headerTemplate` | ❌ | Optional custom header text; supports `{{LICENSE}}`, `{{OWNER}}`, `{{YEAR}}` placeholders |
| `dependencyPolicy` | ❌ | Approved dependency licenses (empty = allow all) |

---

## §5. ENFORCEMENT MECHANISMS

### §5.1 Pre-Commit Governance

A Git pre-commit hook **SHALL** be established to:
- Halt illegal code before it propagates
- Protect future generations from license violations
- Remind developers of their civic obligation

To temporarily bypass (use sparingly):
```bash
git commit --no-verify
```

### §5.2 Continuous Integration

GitHub Actions workflow **SHALL** be generated at `.github/workflows/legal-bro.yml`:

```yaml
name: Legal Compliance Check

on: [pull_request, push]

jobs:
  legal-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y jq
      - run: totally-legal-bro check
```

---

## §6. SUPPORTED JURISDICTIONS (Languages)

The Bro recognizes the following dialects:

**Hash Comments (`#`)**: Python, Ruby, Bash, LaTeX
**Block Comments (`/* */`)**: JavaScript, TypeScript, Go, Rust, C/C++, Java, PHP

**Automatically Exempt**: JSON, TOML, YAML, XML, Markdown (data/config files)

### Example Header

```javascript
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright © 2025 Your Name
 */
```

---

## §7. EDGE CASES & SPECIAL PROVISIONS

### §7.1 Shebang Preservation
Shebang lines (`#!/usr/bin/env python3`) **SHALL** remain at line 1, with headers inserted immediately after.

### §7.2 Respect for `.gitignore`
The Bro **SHALL** only examine files returned by `git ls-files`, thus honoring `.gitignore` as divine scripture.

### §7.3 Non-Duplication Doctrine
Existing correct headers **SHALL NOT** be duplicated, lest chaos ensue.

### §7.4 Copyright Symbol Flexibility
The Bro accepts both `©` and `(c)` as valid copyright indicators.

---

## §8. INSTALLATION

```bash
# Clone and add to PATH
git clone https://github.com/flyingrobots/totally-legal-bro.git
cd totally-legal-bro
export PATH="$PWD:$PATH"  # Add this to your shell rc file

# Or just run it directly
./totally-legal-bro --help
```

> Docker builds expect the tracked `licenses/` directory (with license templates) to be present in the build context—keep it in place or your build will fail.

**Requirements**: Bash, git, jq

---

## §9. TESTING REGIME

The Bro **SHALL** maintain a test suite of no less than 35 tests.

```bash
./test.sh
```

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) and Docker for hermetic isolation.

Current test status: **35/35 passing** ✅

---

## §10. CONTRIBUTING

Pull requests are hereby authorized and encouraged.

1. Fork the repository
2. Create your feature branch
3. Run `./totally-legal-bro check` before committing
4. Submit a PR with extreme confidence

This repository uses totally-legal-bro on itself (dogfooding as a legal mandate).

---

## §11. LICENSE

This project is licensed under the Apache-2.0 License - see the [LICENSE](./LICENSE) file for details.

---

## §12. RATIFICATION

This Act **SHALL** be binding upon all who invoke The Bro.

By executing `totally-legal-bro init`, you consent to:
- Legal compliance
- Reduced technical debt
- Feeling pretty good about your repo

---

<div align="center">

**Made with ☕, Bash, and an unreasonable amount of legal energy**

Questions? Issues? Summon The Bro here: https://github.com/flyingrobots/totally-legal-bro/issues

🤙 *Stay legal, stay chill* 🤙

</div>
