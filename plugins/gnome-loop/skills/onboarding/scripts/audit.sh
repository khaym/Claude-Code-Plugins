#!/bin/bash
# audit.sh — the machine-checkable half of the gnome-loop onboarding audit.
#
# Checks the host prerequisites the loop reads at lap start, plus the wiring
# facts onboarding needs (trigger line, version control of slot files).
# Judgment checks (net inventory, verify-contract conformance) stay in the
# onboarding SKILL.md — this script reports only what a machine can decide.
#
# Usage: audit.sh [repo-root] [--cache-dir DIR]
#   repo-root    host repository root (default: current directory)
#   --cache-dir  plugin cache root to resolve the tracker from
#                (default: ~/.claude/plugins/cache; tests pass a fixture)
#
# Output: one line per item — <item> <status> <detail>
#   Required items (any `missing` sets exit 1):
#     config tracker tracker-data verify-skill observe-skill trigger-line
#   vcs: tracked (ok) | ignored <files> (informational — wire
#     untracked_assets) | no-git (sets exit 1: the loop needs worktrees)
#   lanes: informational pattern-lane count
#
# Exit codes:
#   0  minimal novel-lane operation can start
#   1  gaps found (each named `missing` or `no-git` above)
#   64 usage error

set -u

usage() { echo "usage: audit.sh [repo-root] [--cache-dir DIR]" >&2; exit 64; }

ROOT="."
CACHE_DIR="$HOME/.claude/plugins/cache"
while [ $# -gt 0 ]; do
  case "$1" in
    --cache-dir) [ $# -ge 2 ] || usage; CACHE_DIR="$2"; shift 2 ;;
    -*) usage ;;
    *) ROOT="$1"; shift ;;
  esac
done

cd "$ROOT" 2>/dev/null || usage

GAPS=0
report() { printf '%-13s %-8s %s\n' "$1" "$2" "$3"; }
gap() { report "$1" "$2" "$3"; GAPS=1; }

# --- required items -----------------------------------------------------------

if [ -f .claude/gnome-loop.toml ]; then
  report config ok ".claude/gnome-loop.toml"
else
  gap config missing ".claude/gnome-loop.toml (schema: the gnome-loop skill's config.example.toml)"
fi

TASK_SH=$(ls "$CACHE_DIR"/*/task-tracker/*/scripts/task.sh 2>/dev/null | sort -V | tail -1)
if [ -n "$TASK_SH" ]; then
  report tracker ok "$TASK_SH"
else
  gap tracker missing "no task-tracker plugin under $CACHE_DIR (install it, or supply a same-interface script)"
fi

if [ -d .tasks ]; then
  report tracker-data ok ".tasks/"
else
  gap tracker-data missing ".tasks/ (run task.sh init at the repo root)"
fi

for s in verify observe; do
  if [ -f ".claude/skills/$s/SKILL.md" ]; then
    report "$s-skill" ok ".claude/skills/$s/SKILL.md"
  else
    gap "$s-skill" missing ".claude/skills/$s/SKILL.md"
  fi
done

if [ -f CLAUDE.md ] && grep -q 'dev-cycle' CLAUDE.md; then
  report trigger-line ok "CLAUDE.md mentions dev-cycle (MUST form is judged by the skill)"
else
  gap trigger-line missing "no dev-cycle trigger line in CLAUDE.md"
fi

# --- informational ------------------------------------------------------------

LANE_NAMES=$(grep -l 'lane: pattern' .claude/skills/*/SKILL.md 2>/dev/null \
  | xargs -r -n1 dirname | xargs -r -n1 basename | paste -sd' ' -)
if [ -n "$LANE_NAMES" ]; then
  report lanes info "$(echo "$LANE_NAMES" | wc -w) pattern lane(s): $LANE_NAMES"
else
  report lanes info "no pattern lanes (expected on a fresh host)"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IGNORED=""
  for f in .claude/gnome-loop.toml .claude/skills/verify/SKILL.md .claude/skills/observe/SKILL.md; do
    [ -f "$f" ] && git check-ignore -q "$f" && IGNORED="$IGNORED $f"
  done
  if [ -n "$IGNORED" ]; then
    report vcs ignored "${IGNORED# } (worktrees will not see these; wire config untracked_assets)"
  else
    report vcs tracked "existing slot files are under version control"
  fi
else
  gap vcs no-git "not a git repository (the loop needs worktrees)"
fi

exit "$GAPS"
