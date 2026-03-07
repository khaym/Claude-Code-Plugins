# checking-oss-release Design Doc

## Purpose

Automate pre-release checks for open source projects to catch security/privacy leaks and license compliance issues. Quick mode runs as a PreCommit hook; Full mode runs manually before release.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Three modes: setup / quick / full | Setup installs git hooks; Quick runs on every commit; Full for pre-release audit |
| Custom SubAgent (oss-checker) | File scanning is context-heavy; Custom SubAgent provides reliable context isolation with tool restrictions and model selection |
| Tools: Read, Bash, Grep, Glob | Minimum tools needed for file scanning; no write access required |
| Model: sonnet | File scanning and pattern matching; opus not needed |
| Git email in quick mode | Personal email in commit history is a common oversight; must catch before every commit |
| Gitignore in quick mode | Prevents committing .env / keys; lightweight check worth running every time |
| Email scan in full mode only | Emails in source files are rare; not worth the cost on every commit |
| Grep/Glob-based scanning | No external tools needed; works in any project |
| PASS/WARN/FAIL severity | FAIL blocks release, WARN is advisory, PASS is clear |
| License matrix as reference file | Avoids external API dependency; easy to update |

## Data Flow

### Setup mode
1. Create `.githooks/pre-commit` script (Quick checks as shell script)
2. Add `"prepare": "git config core.hooksPath .githooks"` to package.json
3. Run `npm run prepare` to activate
4. Verify: `git config core.hooksPath` → `.githooks`

### Quick mode (PreCommit)
1. `git config user.email` → check for noreply
2. `git diff --cached --name-only` → staged files → secret pattern scan
3. Read `.gitignore` → verify coverage of sensitive patterns
4. Output: PASS/FAIL summary

### Full mode (manual)
1. Quick checks against all tracked files
2. Email/personal info scan on all source files
3. Read LICENSE → identify license type
4. Read each dependency's package.json → license field → compare against matrix
5. Check THIRD_PARTY_LICENSES existence
6. Output: structured report with all findings

## Constraints & Tradeoffs

- Pattern-based secret detection may produce false positives
- License detection relies on package.json `license` field; missing fields flagged as WARN
- Only supports npm/Node.js dependency trees (extensible later)
- Quick mode skips license checks to stay fast
- Test files and docs are excluded from secret scan to reduce noise
