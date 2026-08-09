# ticket-authoring Design Doc

## Purpose

LLM-assisted development drifts toward code-centric tickets: filed from what the code needs (a refactor, a missing convention) rather than what a user gains. When code vocabulary takes the ticket's subject position, the most important things — what to build, whose value it serves, why — drop out, and the means becomes the end. The cost arrives late: the work clings to existing code until rework surfaces at review that only a rethink of the approach can fix; dependencies between tickets become unreadable; and when other tickets change the code underneath, what was to be done is lost with it. This skill is the antibody: tickets written as user stories are anchored to value the code cannot invalidate, and a premise audit detects when a draft has slipped back to code-anchoring.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Skill + review agent pair, composed via `skills:` (DI) | Same shape as docs-authoring / skill-authoring: criteria live once in the skill; the agent preloads it — no duplication, no cross-reference drift |
| Outside reader as the detection instrument | A reader who knows nothing about the code cannot restate a code-anchored purpose; being able to restate who gains what is what separates value-anchored tickets from code-anchored ones. The reader is the instrument of the audit, not the audience the rules serve |
| Review scope = premise validity only (T1–T5) | Prose readability is a general writing concern (docs-authoring's domain when installed); this plugin audits one thing — whether the ticket's purpose is still in charge of its means |
| Value anchor: caller-provided → repo purpose doc → generic standard | The plugin cannot know a project's purpose. The agent uses a caller-provided anchor first, else discovers a purpose section in CLAUDE.md / README, else falls back to the generic external-anchoring standard and reports the missing anchor itself |
| Tracker-agnostic input; task-tracker as documented integration | A pasted draft or file path always works. Tracker-ID resolution is documented for the sibling task-tracker plugin but its absence only narrows input forms, never blocks the audit |
| Hygiene-only proposals default to "do not file" | A ticket that cannot state its user value is a means with no purpose to serve; filing it institutionalizes the means. The default proposal is recording it in the project's development log instead |
| No `model` pin on the agent | Sibling review agents inherit the session model; a pin would fail for users without access to that model. Callers can still override at invocation time |

## Data Flow

- **Authoring**: user intent → guidelines.md rules applied in the main session → draft → audit pass (ticket-review agent) → findings folded back → filed ticket.
- **Audit**: ticket (pasted draft / file path / tracker ID) → ticket-review agent (isolated context, this skill preloaded) → reads guidelines.md + checklist.md → resolves the value anchor → scores T1–T5 → findings report back to the main session.

## Constraints & Tradeoffs

- Tracker-ID input depends on the task-tracker plugin's `task.sh`; other trackers require the caller to paste the ticket body.
- Value-anchor auto-discovery is heuristic: a repository whose purpose statement lives elsewhere (wiki, external doc) rates T2 against the generic standard unless the caller passes the anchor explicitly.
- The checklist judges premises, not truth: a ticket can pass T1–T5 while being strategically wrong — that judgment stays with the human.

## History

Promoted 2026-08 from a project-local agent (`tui-game` `.claude/agents/ticket-review.md`) after the audit proved effective in that project's filing gate.
