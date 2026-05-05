# hardening-uv-config Design Doc

## Purpose

Reduce PyPI supply chain attack surface by writing uv hardening settings into project config files. Operates as the configuration-time prevention layer of the `hardening-dev-environment` plugin for Python projects: prevention by configuration, not detection at runtime. See `hardening-overview` for the full Layered Defense Map.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Main session execution | Requires user confirmation for migration, build-isolation overrides, and merge conflicts; not suitable for fully autonomous runs |
| Target uv only (not pip / pip-tools / poetry / pdm) | Hardening keys (`exclude-newer`, `required-version`, `index-strategy`) need a config file location for permanent enforcement. pip 26.1 has `--uploaded-prior-to` but only as a CLI flag, not a `pip.conf` entry — it cannot deliver the same guarantee. Supporting every Python package manager would multiply the rule matrix without changing the security model |
| Migration to a uv-native shape is in scope | Settings live in `pyproject.toml [tool.uv]`. Without that table, the hardening cannot be expressed declaratively. Migration is a prerequisite for the prevention layer to take effect, not an optional convenience |
| Auto-migration limited to `requirements.txt` and simple `setup.py` | These have static dependency lists that map cleanly to `[project.dependencies]`. Poetry / Pipenv / pdm projects own a different lockfile and tooling expectation; auto-rewriting risks data loss. Mirrors `hardening-pnpm-config`'s decision to not migrate npm/yarn projects |
| Show diff before every write | Config files often hold project-specific tuning; opaque overwrites destroy trust |
| `exclude-newer = "P3D"` (72-hour sliding window) | Mirrors `hardening-pnpm-config`'s `minimumReleaseAge: 4320` rationale — malicious packages are typically removed within 24–48 hours; 72 hours adds safety margin while still allowing reasonable update cadence. Duration form (not RFC 3339 timestamp) keeps the window sliding rather than freezing the project to a fixed cutoff |
| `index-strategy = "first-index"` written explicitly even though it is the default | A future uv release could change the default; the project's intent ("never resolve a package on a later index if the first index has it") should be expressed in the config rather than relying on tool defaults. Defends against dependency confusion at config layer |
| `no-build-isolation-package = []` written explicitly | Default-secure declaration: every package builds in isolation. Per-package opt-out requires an explicit list entry, making the security degradation visible in version control |
| `no-build = true` is opt-in, not default | Disallowing all source distributions blocks projects whose deps lack wheels for the target Python or platform (common in ML/data stacks). Recommending it by default would push users to disable hardening entirely |
| Recommended OSS (pip-audit / safe-chain / OSV-Scanner) is guidance only, not auto-install | All three are global / per-developer / CI decisions exceeding the skill's blast radius. Same rationale as `hardening-pnpm-config` |
| Pre-commit hook template is opt-in | Not every project uses `.githooks/`; pushing it by default is intrusive |
| `pip install` / `pipx` migration is a self-contained Step 7, not interleaved with config writing | Config writing (Steps 1–6) and command rewriting target different files and need separate per-file approval; nesting them would muddle the diff confirmation flow |
| Documentation files (`*.md`, `*.txt`, etc.) excluded from `pip` / `pipx` scan | README example commands are intent-laden — auto-replacing them can change the meaning of the doc. User decides on a case-by-case basis |
| `@latest` rejected as a resolved version tag for `uvx` | A floating `@latest` reproduces the unpinned-execution risk that motivated migrating away from `pipx run` in the first place |
| Freedom level: Medium | Recommended values are fixed, but migration source/target judgment, build-isolation overrides, and `pip` replacement versions need flexibility |

## Data Flow

```
Input: project root with pyproject.toml | requirements.txt | setup.py
  ↓
Step 1: Detect — uv version, pyproject.toml shape,
                 lockfiles and legacy markers (requirements*.txt,
                 setup.py, poetry.lock, Pipfile, pdm.lock)
  ↓
Step 2: Migrate — for requirements-only / setup.py-only:
                  uv init --bare → uv add -r requirements.txt
                  → uv lock. Pyproject (non-uv) skips dep import.
                  Other (poetry / Pipenv / pdm) exits with guidance.
  ↓
Step 3: Plan — compute additions/modifications for each [tool.uv] key
  ↓
Step 4: Confirm — present consolidated diff per file,
                  user accepts/rejects per file
  ↓
Step 5: Apply — Edit existing files, Write new ones, re-read to verify
  ↓
Step 6: Verify — rm -rf .venv uv.lock && uv sync,
                 check exclude-newer, required-version,
                 first-index index-strategy enforcement
  ↓
Step 7: Migrate pip / pipx → uv add / uvx — git ls-files scan
                 (excluding *.md), classify auto vs report-only,
                 resolve versions via uv pip index versions,
                 per-file diff confirmation, Edit
  ↓
Step 8: Guide — print install commands for pip-audit, safe-chain,
                OSV-Scanner; offer optional pre-commit hook template
```

## Setting Rationale

The four hardening keys are defined operationally (location, value, format) in `SKILL.md`. Their security rationale is recorded here:

| Key | Security rationale |
|-----|--------------------|
| `required-version` | Pinning uv itself prevents silent toolchain drift that could change resolution or build behavior across developers and CI |
| `exclude-newer` | Empirical observation: malicious PyPI packages are typically detected and removed within hours. A waiting period defeats the most common time-pressured attacks |
| `index-strategy` (`first-index`) | Defends against dependency confusion: a malicious public-PyPI package using the same name as a private internal package cannot win resolution if the private index is listed first. uv's default behavior already prevents this; the explicit setting protects against future default changes |
| `no-build-isolation-package` | Without isolation, a package's build backend can read and write the project's environment, which is the threat surface this setting controls. Empty allowlist enforces default-secure; per-package overrides are visible in version control |

Reference: <https://docs.astral.sh/uv/reference/settings/>

## Constraints & Tradeoffs

- uv only. pip / pip-tools / poetry / pdm are out of MVP scope; their projects exit at the migration step with a guidance pointer
- `exclude-newer = "P3D"` may delay legitimate fast-release dependencies; documented escape hatch via `exclude-newer-package`
- `no-build-isolation-package` is a denylist of *isolation*, not the inverse of pnpm's `allowBuilds` (which is an allowlist of *install scripts*). The mapping is asymmetric because uv's default-secure stance is "isolate every build", whereas pnpm's default for install scripts is "block then allow"
- Source-distribution arbitrary code execution at install time is not fully blocked by default. The `no-build = true` opt-in addresses it but breaks projects without wheel coverage; recommended only when the user explicitly confirms wheel-only dependencies
- Does not modify CI scripts or `.github/workflows`; OSV-Scanner CI integration is documented only
- Cannot detect compromise that has already happened. This is prevention, not detection — the runtime and commit-time layers documented in `hardening-overview` handle detection-side concerns
