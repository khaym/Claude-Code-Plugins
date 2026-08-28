# ticket-review Design Doc

## Purpose

A drafting session judges its own tickets too kindly: it knows the internals, so purposes anchored to code convenience still "read fine" from inside. This agent supplies the missing reader — an isolated context with no project knowledge — and reports whether the ticket's purpose is still in charge of its means, before code-anchoring turns into late rework, unreadable dependencies, or intent lost to code churn.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Custom SubAgent, read-only toolset (Read, Grep, Glob, Bash) | The audit's value is the cold context; editing rights would blur reviewer and writer. Bash exists solely to run the tracker's `show` command |
| Preloads `ticket-authoring` via `skills:`, criteria read at runtime | checklist.md / guidelines.md stay the single source of truth; the agent verifies the preload at startup and refuses to audit without it |
| Premise checks only (T1–T5), no readability scoring | Keeps a crisp boundary with docs-review; one finding class per agent keeps reports actionable |
| Value restatement as a mandatory report section | The one-line restatement is the discrimination test made visible — failure to restate is the strongest possible finding, so it cannot be omitted |
| Strict judgment stance stated in the prompt | The writer is another session; without an explicit stance the agent drifts toward benefit-of-the-doubt scoring |
| `maxTurns: 15` as a runaway guard | Anchor discovery may take a few Glob/Read turns but the audit is bounded |
| `model: opus` | Before the pin the agent ran on the session's inherited model, which in the situation that prompted the pin was Fable 5. Scoring T1–T5 needs the judgment to tell a user-anchored purpose from a code-anchored restatement. Opus holds that judgment regardless of the session's model. Sonnet was the cheaper alternative, rejected because a gate audit whose judgment degrades stops working as a defense layer. The cost lands where an organization's `availableModels` allowlist blocks opus: the agent runs on the inherited model there. An interactive session warns in that case, naming the requested and the substituted model |

## Data Flow

Ticket (pasted draft / file path / tracker ID) → resolve ticket body → resolve value anchor (caller-provided → CLAUDE.md → README → generic standard) → score T1–T5 against checklist.md → findings report (verdicts, rationales, directions, value restatement) → main session.

## Constraints & Tradeoffs

- Tracker-ID resolution covers the sibling task-tracker plugin only; other trackers require the caller to paste the body.
- The anchor fallback keeps the audit running without a purpose document, at the cost of a weaker T2: the generic standard checks for *an* external anchor, not *the project's* anchor.
- Findings are advisory; the agent never blocks filing mechanically — the main session and the human decide.
