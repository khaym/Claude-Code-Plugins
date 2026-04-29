# hardening-pnpm-config Design Doc

## Purpose

Reduce npm supply chain attack surface by writing pnpm 10.26+ hardening
settings into project config files. Operates as the L0 prevention layer
of the `hardening-dev-environment` plugin: prevention by configuration,
not detection at runtime.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Main session execution | Requires user confirmation for `allowBuilds` entries and merge conflicts; not suitable for fully autonomous runs |
| Target pnpm 10.26+ only | All target keys (`allowBuilds`, `blockExoticSubdeps`, `strictDepBuilds`) require this version. Supporting older versions doubles the rule matrix |
| Edit existing files, not generate from scratch | Most projects already have partial `.npmrc` / `pnpm-workspace.yaml`; full replacement is destructive |
| Show diff before every write | Config files often hold project-specific tuning; opaque overwrites destroy trust |
| `minimumReleaseAge: 4320` (72 hours) | Industry observation that malicious packages are typically removed within 24–48 hours. 72 hours adds safety margin while still allowing reasonable update cadence |
| Recommended OSS (safe-chain / OSV-Scanner) is guidance only, not auto-install | `safe-chain` is a global install with shell alias setup; OSV-Scanner is a CI/pre-commit decision. Both exceed the skill's blast radius |
| Pre-commit hook template is opt-in | Not every project uses `.githooks/`; pushing it by default is intrusive |
| Freedom level: Medium | Recommended values are fixed, but `allowBuilds` entries and merge decisions need flexibility |

## Data Flow

```
Input: project root with package.json (Node.js project assumed)
  ↓
Step 1: Detect — pnpm version, packageManager field,
                 existing .npmrc / pnpm-workspace.yaml
  ↓
Step 2: Plan — compute additions/modifications for each target key,
               enumerate install-script candidates from node_modules
  ↓
Step 3: Confirm — present consolidated diff per file,
                  user accepts/rejects per file
  ↓
Step 4: Apply — Edit existing files, Write new ones, re-read to verify
  ↓
Step 5: Verify — rm -rf node_modules pnpm-lock.yaml && pnpm install,
                 check YAML parse, allowBuilds postinstall logs,
                 ERR_PNPM_IGNORED_BUILDS on empty allowlist
  ↓
Step 6: Guide — print install commands for safe-chain and OSV-Scanner;
                offer optional pre-commit hook template
```

## Setting Rationale

The five hardening keys are defined operationally (location, value, format)
in `SKILL.md`. Their security rationale is recorded here:

| Key | Why this is the L0 layer |
|-----|--------------------------|
| `packageManager` | Pinning pnpm itself prevents silent toolchain drift that could change install behavior across developers and CI |
| `minimumReleaseAge` | Empirical observation: malicious packages are typically detected and removed within hours. A waiting period defeats the most common time-pressured attacks |
| `blockExoticSubdeps` | Transitive git/tarball sources bypass the registry's checks entirely; rejecting them closes a path that lockfiles do not protect |
| `strictDepBuilds` | Without this, a missing entry in `allowBuilds` is a warning rather than a hard failure — degrading the policy to advisory |
| `allowBuilds` | Install scripts are the most common malware execution vector. Default-deny with explicit allowlist makes adding a new dependency a conscious decision |

Reference: <https://pnpm.io/supply-chain-security>

## Constraints & Tradeoffs

- Node.js / pnpm only. npm / yarn / bun are out of MVP scope
- `minimumReleaseAge: 4320` may delay legitimate fast-release dependencies;
  documented escape hatch via `minimumReleaseAgeExclude`
- `allowBuilds` requires per-package judgment; the skill enumerates candidates
  from `node_modules` but cannot decide for the user
- Does not modify CI scripts or `.github/workflows`; OSV-Scanner CI integration
  is documented only
- Cannot detect compromise that has already happened. This is prevention,
  not detection — the L1+ layers in future plugin phases handle detection
