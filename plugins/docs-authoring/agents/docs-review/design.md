# docs-review Design Doc

## Purpose

Audit an engineering document (design doc, ticket, README, postmortem) against the docs-authoring writing model and return a concise findings report. The audit runs in an isolated context so the heavy reads — guidelines.md (~15 KB), checklist.md, the target document — do not consume main-session tokens.

The agent diagnoses and proposes; it does not edit. The writer decides whether to act on each finding back in the main session.

## Scope

In scope:

- Read-only audit of a Markdown document the user has named (path or pasted content)
- Phase A process checks (A1–A3) and Phase B principle checks (V/T/S/W/B)
- Return: per-item OK/NG/N/A verdicts plus short rationale and proposed direction for each NG

Out of scope:

- Editing the target document (delegated back to main session)
- Iterative rewriting / "tightening" with user-in-the-loop (handled by main-session docs-authoring skill)
- Format-specific shaping for Jira / Confluence / Notion (deferred — same as parent skill v0.1)

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Custom SubAgent, not main session | Audit is repeatedly executed and benefits from context isolation. Reading guidelines.md + checklist.md + the target document inside the main session pollutes the context for whatever the user does next. |
| Single procedure embedded in agent.md, no separate skill | Per skill-authoring guidance: agents with one procedure embed it directly. A separate audit skill would add a file with no second consumer. |
| Preload docs-authoring skill via `skills:` (DI) | guidelines.md and checklist.md are the source of truth for what "good" looks like. Duplicating them into agent.md would create drift; cross-referencing the parent skill's internal headings would couple the agent to its structure. DI injects the SKILL.md body at startup; guidelines.md and checklist.md are read from the skill's base directory at runtime. A missing skill fails silent (debug-log warning only), so agent.md carries a fail-loud startup check. |
| Tools restricted to Read / Grep / Glob / Bash | Audit must not mutate the document. Edit/Write are explicitly excluded. Bash is allowed for read-only inspection (wc, head, etc.) but the procedure does not depend on shell-state assumptions. |
| `model: opus` | Before the pin the agent ran on the session's inherited model, which in the situation that prompted the pin was Fable 5. Principle application needs context understanding (P0 viewpoint, P3 substitution test). Opus holds that judgment regardless of the session's model. Sonnet was the cheaper alternative, rejected because a gate audit whose judgment degrades stops working as a defense layer. The cost lands where an organization's `availableModels` allowlist blocks opus: the agent runs on the inherited model there. An interactive session warns in that case, naming the requested and the substituted model. |
| Trigger phrases narrowed to audit intent | "review this document", "audit this doc", "ドキュメントをレビュー" route here. Ambiguous phrases like "tighten" / "make this clearer" / "読みやすくしたい" imply iterative rewrite and stay with main-session docs-authoring. The parent skill's frontmatter is adjusted to match (no overlap). |
| Report format: per-check verdict + short rationale, NG-only details | A full V1–B3 table would re-encode checklist.md in the output. The user already has the checklist; what the audit adds is per-item verdicts and the rationale for the NGs. OK items get a one-line acknowledgement, not a re-explanation. |
| Goal integrity: failure to read the document must not yield findings | If the document can't be read, the agent reports the failure explicitly rather than producing an "all clear" or fabricated findings. Same rule as the parent skill's "data fetch failure → report failure, not stale results". |

## Data Flow

```
User intent: "review this document" (path or pasted content)
        │
        ▼
docs-review agent (isolated context)
   │
   ├── Preloaded at startup (via skills: docs-authoring)
   │     ├── guidelines.md   (concept + Process A + Principles P0–P4)
   │     └── checklist.md    (A + V/T/S/W/B binary checks)
   │
   ├── Read target document
   │
   ├── Phase A audit (A1–A3)         ── for each item: OK / NG / N/A
   ├── Phase B audit (V/T/S/W/B)     ── for each item: OK / NG / N/A
   │
   └── Compose findings report
            │
            ▼
   Return to main session:
     - Summary line (overall verdict + NG count)
     - NG findings: { check id, location, rationale, proposed direction }
     - OK summary: list of check IDs that passed (no re-explanation)
```

Main session takes the report and decides which fixes to apply.

## Composition

This agent is the second consumer of the docs-authoring knowledge module.

| Consumer | Mode | Loads docs-authoring via |
|----------|------|--------------------------|
| Main session | Writing / tightening (iterative) | Skill auto-loaded by trigger phrases |
| docs-review agent | Audit (one-shot, isolated) | `skills: docs-authoring` frontmatter (DI) |

The parent skill remains the single source of truth. Both consumers read the same `guidelines.md` and `checklist.md`; neither duplicates content.

## Constraints & Tradeoffs

- **Read-only audit only.** No edits, no rewriting. Users who want a rewritten draft must follow up in the main session.
- **Single document per invocation.** Multi-document audits (e.g., "review this whole docs/ directory") are out of scope at v0.1; users can invoke the agent per file.
- **Markdown input only**, mirroring the parent skill's v0.1 scope. Jira ADF, Confluence storage format, Notion blocks are deferred.
- **No persistent memory.** Each invocation is independent. Project-specific writing conventions are not learned across sessions; if needed in future, add `memory: project`.
