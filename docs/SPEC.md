# 📝 totally-legal-bro Spec Sheet (The Blueprint)

## 🤙 1. Overall Architecture Vibe

The tool runs off the CLI. It's gotta be super fast, so we aren't doing any crazy database stuff. The entire vibe is built around three core principles:

**Trust git**: We use `git ls-files` for everything. If Git ignores it (`.gitignore`), we ignore it. Low effort, high payoff.

**The Target Vibe (Config)**: Every check relies on a single, minimal config file: `.legalbro.json`.

**The Fix is Automatic**: If the check fails, `fix` should be able to solve, like, 90% of the common screw-ups (missing headers, missing files).

## ⚙️ 2. The Target Vibe: `.legalbro.json`

This file defines what the legal sitch should be. It lives at the root of the repo.

| Field | Type | Description |
|-------|------|-------------|
| `requiredLicense` | string | MANDATORY. The SPDX ID for the main repo license (e.g., "MIT", "Apache-2.0"). Used to check the LICENSE file and headers. |
| `ownerName` | string | MANDATORY. The copyright holder's name for new headers (e.g., "The Totally Legal Bro Team"). |
| `headerTemplate` | string | OPTIONAL. A custom template string for SPDX headers if the default isn't chill enough. |
| `dependencyPolicy` | array<string> | OPTIONAL. A list of APPROVED SPDX licenses for external dependencies. If a dependency license isn't on this list, check fails. |

### Example Config (`.legalbro.json`):

```json
{
  "requiredLicense": "MIT",
  "ownerName": "Totally Legal Bro Enterprises",
  "dependencyPolicy": [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause"
  ]
}
```

## 💻 3. Command Logic (What Each Command Does, Bro)

### `totally-legal-bro check`

**Repo File Check**:
- Find and validate existence of LICENSE file. Compare its SPDX against `requiredLicense` in config.
- Check for NOTICE file presence.
- Check README.md for a license section that mentions `requiredLicense`.

**Artifact Header Check**:
- Use `git ls-files` to get every tracked file.
- Skip: Files without standard comments (like .txt, images, assets) and files in the default exclude list (can be extended via config later).
- Check the first 20 lines of every source file for the correct SPDX identifier and Copyright line matching `ownerName`.

**Dependency Check (The External Sitch)**:
- Scan known manifest files (package.json, requirements.txt, etc.).
- Use an internal library (or external tool hook) to map installed dependencies to their licenses.
- **CRITICAL**: If any dependency license is not in the `dependencyPolicy` list, the check fails hard.
- **Deep Scanning**: For `npm`, the scanner traverses the full `node_modules` tree (no depth limit) to catch all transitive dependencies. It uses optimized batched processing to handle large dependency trees efficiently.

### `totally-legal-bro fix` (The Wizard Mode)

- If LICENSE is missing, create a template using `requiredLicense`.
- If NOTICE is missing, create an empty boilerplate.
- If README.md is missing the license section, append the legal boilerplate.
- For any file identified by `check` as missing a header, inject the correct SPDX header using the configured `requiredLicense` and `ownerName` at the top of the file, respecting the file's comment style (e.g., `#` for Python, `//` for JS, `/* */` for C).
- **Robustness**: Uses portable regex syntax to reliably replace placeholders (like `[yyyy]`) across different `sed` versions (GNU/BSD).

### `totally-legal-bro init` (Getting Wired Up)

- Creates the mandatory `.legalbro.json` file if it doesn't exist, using defaults and prompting the user for `requiredLicense` and `ownerName`.
- Sets up a Git pre-commit hook that automatically runs `totally-legal-bro check` on modified files before a commit is allowed.
- Generates boilerplate CI job configs (e.g., `.github/workflows/legal-bro.yml`) that run `totally-legal-bro check` on every pull request.

### `totally-legal-bro report`

- Re-runs all checks.
- Outputs a structured, human-readable report listing:
  - The required license (from config).
  - Status (PASS/FAIL) for all repo files.
  - List of files missing headers.
  - List of dependency licenses found and those that violate `dependencyPolicy`.

---

That's the spec, bro. It handles the core repo files, the headers, the external libraries, and has auto-fix/enforcement built in. We should start coding up that config file logic first. That's the foundation. Trust.
