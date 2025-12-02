# ⚖️ THE TOTALLY-LEGAL-BRO ACT OF 2025

> (As Ratified by the League of Extraordinary DevOps, the Senate of Legit Open Source, and the Respected Elders of the Counsil on SPDX)

---

<div align="center">
An Act
To impose order upon chaotic repos, ensure the presence of LICENSE files, regulate SPDX header proliferation, suppress unlicensed dependencies, and maintain the sanctity of the Vibes.
</div>

---

## TITLE I — PRELIMINARY FINDINGS

### §1. PREAMBLE

**WHEREAS**, developers continue to commit unspeakable acts such as:

- pushing code without a LICENSE,  
- omitting SPDX headers,
- introducing GPL-3.0 deps into MIT projects “because it worked on their machine,”

**AND WHEREAS**, such behavior constitutes a threat to national stability, international peace, and CI pipelines everywhere;

**AND WHEREAS**, humanity has suffered enough;

**THEREFORE**, be it enacted by the Authority vested in The Bro:

> `totally-legal-bro` SHALL keep your repo totally legal, bro™. No cap, this is legit binding.

## TITLE II — DEFINITIONS

1. **“The Bro”** — a Bash-based legal enforcement entity of great and terrible power.
2. **“Subject Repository”** — any Git territory not yet brought into the light.
3. **“SPDX Header”** — the sacred runes that ward off legal demons.
4. **“Fix Mode”** — a ritual cleansing comparable to baptism.
5. **“The Operator”** — whoever runs the command; includes humans, AIs, cronjobs, and ghosts in abandoned servers.
6. **“The Stoke”** — the metaphysical bliss felt when a repo becomes compliant.
7. **“Illegal Code”** — any file lacking proper headers or licensing, punishable by shame.
8. **“CI Wrath”** — the swift and merciless failure of pipelines due to compliance violations.

## TITLE III — INSTALLATION PROCEDURES

### §1.1 INSTALLATION PROCEDURE

Failure to follow these steps SHALL result in undefined behavior, divine disappointment, or both.

#### §1.1(a) Ritual Cloning

```bash
git clone https://github.com/flyingrobots/totally-legal-bro.git && cd totally-legal-bro
```

#### §1.1(b) Invocation of the Install Script

```bash
./install.sh
```

This SHALL:

- Install The Bro to `~/.totally-legal-bro`,
- Configure `PATH` entries,
- And mark your soul for audit.

#### §1.1(c) Path Reconciliation Clause

```bash
export PATH="$HOME/.totally-legal-bro:$PATH"
```

#### §1.1(d) Initialization Rites (per repo)

```bash
totally-legal-bro init
```

The Bro SHALL create an empty `.legalbro.json` (the Binding Covenant).   

The Operator SHALL be obligated to fill in details found within `.legalbro.json` to ensure accurate application of The Stoke.

#### §1.1(e) Atonement and Verification

```bash
totally-legal-bro fix && totally-legal-bro check
```

Declares the repo Totally Legal™ under international law.

#### §1.1(f) Windows Exception

**WHEREAS** Windows machines remain a plane of suffering;
**THEREFORE** The Bro MAY NOT function there. 
**HENCEFORTH** pull requests addressing this issue SHALL be treated as acts of heroism.

## TITLE IV — POWERS OF THE BRO

### §2.1 Summoning Ritual

```bash
totally-legal-bro init
```

Generates governance artifacts with extreme prejudice (config, hooks, CI scaffold).

### §2.2 Corrective Measures (Fix Mode)

```bash
totally-legal-bro fix [--no-headers | --headers-only]
```

- Conjures `LICENSE`/`NOTICE` if missing
- Injects SPDX headers (honors shebangs, comment styles, `.gitignore`)
- Ensures README license section matches config

### §2.3 Verification of Legal Integrity

```bash
totally-legal-bro check [--json] [--manifests path1,path2]
```

- Validates `LICENSE` contents
- Verifies `README` license mention
- Audits SPDX headers
- Scans dependency licenses (npm by inspecting `node_modules/*/package.json` licenses; others `TODO`; warns if `node_modules` absent if `package.json` exists)

### §2.4 Reporting Requirements

```bash
totally-legal-bro report [--json]
```

Produces a dossier: file status, dependency findings, vibe score (beta, spiritual).

## TITLE V — ENFORCEMENT (NOW WITH FEDERAL MENACE)

### §5.1 Pre-Commit Governance Structure

Git pre-commit hook SHALL block illegal code.  
Bypassing with `--no-verify` SHALL be logged in the Book of Transgressions, and is generally frownd upon, dude.  

### §5.2 Continuous Integration Tribunal

GitHub Actions workflow (`.github/workflows/legal-bro.yml`) SHALL smite PRs that offend the Vibes.

## TITLE VI — CONFIGURATION

The Subject Repository SHALL maintain `.legalbro.json` at its root:

```json
{
  "requiredLicense": "Apache-2.0",
  "ownerName": "Your Name <you@example.com>",
  "headerTemplate": "/*\n * SPDX-License-Identifier: {{LICENSE}}\n * Copyright (c) {{YEAR}} {{OWNER}}\n */",
  "dependencyPolicy": ["MIT", "Apache-2.0", "BSD-3-Clause"]
}
```

| **Field** | **Required** | **Purpose** |
|-------|----------|---------|
| `requiredLicense` | ✅ | SPDX license identifier (e.g., `MIT`, `Apache-2.0`) |
| `ownerName` | ✅ | Copyright holder name and/or email |
| `headerTemplate` | ❌ | Custom header; supports `{{LICENSE}}`, `{{OWNER}}`, `{{YEAR}}` |
| `dependencyPolicy` | ❌ | Approved dependency licenses (empty = allow all) |

## TITLE VII — DEPENDENCY LICENSE COMPLIANCE

- **npm**: enforced by inspecting `node_modules/*/package.json` license fields; fails on licenses outside `dependencyPolicy`; warns if `node_modules` missing.
- **pip / go / cargo**: TODO; currently warns.
- Absence of policy = all licenses allowed (but you accept the vibes risk).

## TITLE VIII — SUPPORTED JURISDICTIONS (LANGUAGES)

- Hash comments: Python, Ruby, Bash, LaTeX  
- Block comments: JavaScript/TypeScript, Go, Rust, C/C++, Java, PHP   
- Exempt: JSON, TOML, YAML, XML, Markdown (data/config)   

Example header:

```javascript
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright © 2025 Your Name
 */
```

## TITLE IX — EDGE CASES & SPECIAL PROVISIONS

The Bro SHALL:

- Ensure that shebang lines stay first; headers follow.
- Honor `.gitignore` by using `git ls-files` (configurable via `GIT_CMD`).
- Permit common copyright symbols: `©` or `(c)` accepted.

## TITLE X — TESTING REGIME

```bash
./test.sh   # uses docker-compose; add --build to rebuild image
```

Powered by `bats-core` (pinned 1.11.0) and Docker for hermetic vibes.


## TITLE XI — CLI FLAGS (THE BRO CODEX)

- `--version` — print version
- `--config <path>` — alternate `.legalbro.json`
- `--json` — JSON output for check/report
- `--verbose` / `--quiet` — adjust verbosity
- `fix --no-headers` — skip header injection
- `fix --headers-only` — only inject headers
- `check --manifests <paths>` — comma-separated manifest override

## TITLE XII — SUPREME CASE LAW

- **Bro v. The Developer (2025)** — “Forgetting your LICENSE is not a vibe.”
- **CI Pipeline v. Guy Who Imported a GPL Dependency (2024)** — “He knew what he did.”
- **The People v. touch LICENSE With No Contents (2021)** — “Absolutely not.”

## TITLE XIII — THE BRO SEAL OF AUTHENTICITY

```code
      .o.       oooooooooo.        ooooooooo.   ooooo        oooooooooooo ooooo      ooo ooooo     ooo ooo        ooooo                  
     .888.      `888'   `Y8b       `888   `Y88. `888'        `888'     `8 `888b.     `8' `888'     `8' `88.       .888'                  
    .8"888.      888      888       888   .d88'  888          888          8 `88b.    8   888       8   888b     d'888                   
   .8' `888.     888      888       888ooo88P'   888          888oooo8     8   `88b.  8   888       8   8 Y88. .P  888                   
  .88ooo8888.    888      888       888          888          888    "     8     `88b.8   888       8   8  `888'   888                   
 .8'     `888.   888     d88'       888          888       o  888       o  8       `888   `88.    .8'   8    Y     888                   
o88o     o8888o o888bood8P'        o888o        o888ooooood8 o888ooooood8 o8o        `8     `YbodP'    o8o        o888o                  
```

```code
  .oooooo.     .oooooo.   ooooo      ooo oooooooooooo   .oooooo.   ooooooooo.   ooo        ooooo ooooo  .oooooo..o                       
 d8P'  `Y8b   d8P'  `Y8b  `888b.     `8' `888'     `8  d8P'  `Y8b  `888   `Y88. `88.       .888' `888' d8P'    `Y8                       
888          888      888  8 `88b.    8   888         888      888  888   .d88'  888b     d'888   888  Y88bo.                            
888          888      888  8   `88b.  8   888oooo8    888      888  888ooo88P'   8 Y88. .P  888   888   `"Y8888o.                        
888          888      888  8     `88b.8   888    "    888      888  888`88b.     8  `888'   888   888       `"Y88b                       
`88b    ooo  `88b    d88'  8       `888   888         `88b    d88'  888  `88b.   8    Y     888   888  oo     .d8P .o.                   
 `Y8bood8P'   `Y8bood8P'  o8o        `8  o888o         `Y8bood8P'  o888o  o888o o8o        o888o o888o 8""88888P'  Y8P                   
```

```code
oooooooooooo ooooooooo.         .o.       ooooooooooooo oooooooooooo ooooooooo.     .oooooo.   oooooo     oooo ooooo        oooooooooooo 
`888'     `8 `888   `Y88.      .888.      8'   888   `8 `888'     `8 `888   `Y88.  d8P'  `Y8b   `888.     .8'  `888'        `888'     `8 
 888          888   .d88'     .8"888.          888       888          888   .d88' 888            `888.   .8'    888          888         
 888oooo8     888ooo88P'     .8' `888.         888       888oooo8     888ooo88P'  888             `888. .8'     888          888oooo8    
 888    "     888`88b.      .88ooo8888.        888       888    "     888`88b.    888              `888.8'      888          888    "    
 888          888  `88b.   .8'     `888.       888       888       o  888  `88b.  `88b    ooo       `888'       888       o  888       o 
o888o        o888o  o888o o88o     o8888o     o888o     o888ooooood8 o888o  o888o  `Y8bood8P'        `8'       o888ooooood8 o888ooooood8 
```

**DEPARTMENT OF TOTALLY LEGAL AFFAIRS**

---

## TITLE XIV — DISCLAIMER (ABSURD, YET LEGALLY VIBRANT)

### §10.1 ABSOLUTE NON-LIABILITY OF THE BRO

The Bro, its scripts, vibes, and emanations SHALL NOT be liable for damages arising from: use, misuse, overuse, non-use, recursion, sudo piping, Windows, eclipses, sobriety, intoxication, gremlins, daemons, cronjobs, interns, or actions by unsupervised AI.

### §10.2 ASSUMPTION OF RISK BY THE OPERATOR

By invoking The Bro, you ASSUME ALL RISK (known/unknown/ metaphysical) and CONSENT that The Bro may fix, expose sins, reduce debt, raise stoke, or trigger CI failures.

### §10.3 LIMITATION OF LIABILITY

Total liability limited to $0 (unless tipped in vibes). No direct/indirect/ consequential/ reputational/ stoke damages.

### §10.4 NO ATTORNEY-CLIENT RELATIONSHIP

The Bro is not your lawyer, bro.

### §10.5 INDEMNIFICATION CLAUSE

You indemnify The Bro, its creators, bystanders, pets, and anyone who ever said “legalize it (code)” from claims arising from your use.

### §10.6 STOKE PRESERVATION CLAUSE

Even if all else fails, **The Stoke SHALL remain immaculate.**

### §10.7 ACCEPTANCE

Running any Bro command constitutes assent.

## TITLE XV — RATIFICATION

By invoking The Bro, you consent to legal compliance, spiritual cleansing, enhanced vibes, protection of descendants, and a repo you can show your boss without shame.

## TITLE XVI — LICENSE AGREEMENT

Apache-2.0 — see [LICENSE](./LICENSE).

Questions? Issues? Summon The Bro: https://github.com/flyingrobots/totally-legal-bro/issues

---

<div align="center">
🤙 *Stay legal, stay chill* 🤙<br />Copyright © 2025 James Ross, [Flying•Robots](https://github.com/flyingrobots)
</div>
