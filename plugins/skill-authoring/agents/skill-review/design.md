# skill-review Design Doc

## Purpose

Audit a skill directory against the skill-authoring guidelines and quality checklist and return a concise findings report. The audit runs in an isolated context so the heavy reads — guidelines.md, checklist.md, and every file of the target skill — do not consume main-session tokens.

The agent diagnoses and proposes; it does not edit. The author decides whether to act on each finding back in the main session.

## Scope

In scope:

- Read-only audit of one skill directory (standalone `.claude/skills/` or `<plugin-root>/skills/`)
- All checklist layers: G (context design), S/F/C (standard rules), D/A/M (recommended practices)
- Return: per-item OK/NG/N/A verdicts plus short rationale, proposed direction, and Critical/Recommended/Minor priority for each NG

Out of scope:

- Editing the target skill (delegated back to the main session)
- Creating new skills (create-workflow runs in the main session; only its quality-check step delegates here)
- Auditing an agent directory on its own — agents enter the audit only as consumers of the target skill (C10 interface check)

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Custom SubAgent, not main session | The audit is repeatedly executed, needs no user interaction, and needs no main-session context — G2 selection flow: 1.No → 2.No → 3.Yes → Custom SubAgent. Reading guidelines.md + checklist.md + the whole target skill inside the main session pollutes the context for whatever the user does next. |
| Whole audit lives in agent.md — the parent skill has no review workflow file | Per skill-authoring guidance: agents with one procedure embed it directly. A separate review-workflow.md restating the audit steps would duplicate the agent's procedure (C8); the parent skill keeps only the thin main-session loop (invoke → present → agree → implement → re-verify) inside SKILL.md. |
| Preload skill-authoring via `skills:` (DI) | guidelines.md and checklist.md are the source of truth. Duplicating them into agent.md would create drift; cross-referencing headings would couple the agent to the skill's structure. DI injects the SKILL.md body at startup; referenced files are read on demand. A missing skill fails silent (debug-log warning only), so agent.md carries a fail-loud startup check. |
| Tools restricted to Read / Grep / Glob / Bash | The audit must not mutate the target. Edit/Write are excluded. Bash is allowed for read-only inspection (wc, find, etc.). |
| `model: opus` | Before the pin the agent ran on the session's inherited model, which in the situation that prompted the pin was Fable 5. Checklist judgments like C7–C9 (emphasis imbalance, duplication, accretion) need whole-document reading comprehension. Opus holds that judgment regardless of the session's model. Sonnet was the cheaper alternative, rejected because a gate audit whose judgment degrades stops working as a defense layer. The cost lands where an organization's `availableModels` allowlist blocks opus: the agent runs on the inherited model there. An interactive session warns in that case, naming the requested and the substituted model. |
| Priority triage owned by the agent | The report arrives pre-triaged (Critical/Recommended/Minor); the main session presents priorities as-is instead of re-deriving them. |
| M checks parameterized by an optional MEMORY.md path | Auto-memory location is user- and project-specific; the agent cannot discover it reliably from an isolated context. Explicit input keeps the interface unambiguous (C10); omission degrades to N/A, never to a guessed path. |
| Report format mirrors docs-review | Same shape (NG findings / OK summary / N/A) across the two review agents lowers the reading cost for a user who consumes both. |

## Data Flow

```
User intent: "review skill" (skill directory path [+ MEMORY.md path])
        │
        ▼
skill-review agent (isolated context)
   │
   ├── Preloaded at startup (via skills: skill-authoring)
   │     └── guidelines.md / checklist.md / reference files
   │
   ├── Read target skill (SKILL.md, design.md, referenced files, scripts)
   │
   ├── G audit (G1–G6, incl. G2 selection-flow trace)   ── OK / NG / N/A
   ├── S/F/C audit (standard rules)                     ── OK / NG / N/A
   ├── D/A/M audit (recommended practices)              ── OK / NG / N/A
   │
   └── Compose findings report (NGs triaged Critical/Recommended/Minor)
            │
            ▼
   Return to main session:
     - Verdict line + G2 path
     - NG findings: { check id, location, rationale, proposed direction, priority }
     - OK summary / N/A list
```

The main session takes the report and implements approved fixes (the Review Flow in SKILL.md, or create-workflow step 7).

## Composition

This agent is the second consumer of the skill-authoring knowledge module.

| Consumer | Mode | Loads skill-authoring via |
|----------|------|---------------------------|
| Main session | Creation / improvement implementation (interactive) | Skill auto-loaded by trigger phrases |
| skill-review agent | Audit (one-shot, isolated) | `skills: skill-authoring` frontmatter (DI) |

The skill remains the single source of truth. Both consumers read the same guidelines.md and checklist.md; neither duplicates content.

## Constraints & Tradeoffs

- **Read-only audit only.** No edits. Users who want fixes applied follow up in the main session (the Review Flow in SKILL.md).
- **One skill per invocation.** Multi-skill audits (e.g., "review every skill in this plugin") run as one invocation per skill.
- **M checks depend on the caller.** If the caller does not pass a MEMORY.md path, memory integrity is not audited — the report says so via N/A rather than silently passing.
- **No persistent memory.** Each invocation is independent. If cross-session audit knowledge becomes useful, add `memory: user` later.
