# ticket-authoring Design Doc

## Purpose

LLM-assisted development drifts toward code-centric tickets: filed from what the code needs (a refactor, a missing convention) rather than what a user gains. When code vocabulary takes the ticket's subject position, the most important things — what to build, whose value it serves, why — drop out, and the means becomes the end. The cost arrives late: the work clings to existing code until rework surfaces at review that only a rethink of the approach can fix; dependencies between tickets become unreadable; and when other tickets change the code underneath, what was to be done is lost with it. This skill is the antibody: tickets written as user stories are anchored to value the code cannot invalidate, and a premise audit detects when a draft has slipped back to code-anchoring.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Skill + review agent pair, composed via `skills:` (DI) | Same shape as docs-authoring / skill-authoring: criteria live once in the skill; the agent preloads it — no duplication, no cross-reference drift |
| Outside reader as the detection instrument | A reader who knows nothing about the code cannot restate a code-anchored purpose; being able to restate who gains what is what separates value-anchored tickets from code-anchored ones. The reader is the instrument of the audit, not the audience the rules serve |
| Review scope = premise validity only (T1–T5) | Prose readability is a general writing concern (docs-authoring's domain when installed); this plugin audits one thing — whether the ticket's purpose is still in charge of its means |
| Writing skill loads *before* drafting (filing flow step 1) | A writing model loaded first shapes the prose; applied as a post-hoc review it anchors on the existing text and only patches it. Observed 2026-08-10: tickets drafted without the model showed unclear sentence subjects that the premise audit structurally cannot catch |
| Value anchor: caller-provided → repo purpose doc → generic standard | The plugin cannot know a project's purpose. The agent uses a caller-provided anchor first, else discovers a purpose section in CLAUDE.md / README, else falls back to the generic external-anchoring standard and reports the missing anchor itself |
| Tracker-agnostic input; task-tracker as documented integration | A pasted draft or file path always works. Tracker-ID resolution is documented for the sibling task-tracker plugin but its absence only narrows input forms, never blocks the audit |
| Hygiene-only proposals default to "do not file" | A ticket that cannot state its user value is a means with no purpose to serve; filing it institutionalizes the means. The default proposal is recording it in the project's development log instead |
| `model: opus` pin on the agent | Before the pin the agent ran on the session's inherited model, which in the situation that prompted the pin was Fable 5. Scoring T1–T5 needs the judgment to tell a user-anchored purpose from a code-anchored restatement. Opus holds that judgment regardless of the session's model. Callers can still override at invocation time. Sonnet was the cheaper alternative, rejected because a gate audit whose judgment degrades stops working as a defense layer. The cost lands where an organization's `availableModels` allowlist blocks opus: the agent runs on the inherited model there. An interactive session warns in that case, naming the requested and the substituted model |
| Done = one prose outcome sentence plus success criteria | The original "open with the change visible to the user, then list implementation steps" permitted the outcome itself as a `- [ ]` item — an outcome and its steps as siblings, the shape docs-authoring (0.4.1, P2) names as a detour — so docs-review reported the Done structure as a defect on every conforming ticket, and a real content defect hid behind that noise (observed 2026-08-28). Calling the items steps did not settle it: steps chain, so siblings read as a pipeline (0.4.1, S3), and they are means vocabulary (0.4.1, W3) where the goal's end-state vocabulary belongs; four further audits still reported S3, one W3. Success criteria — verifiable end-states, independent of each other — satisfy both checks, and dev-cycle stage 3, gnome-loop and the implementer agent already name this list success criteria. Relaxing P2 / S3 instead was rejected: they are general writing rules other documents rely on |
| Reader/role-declaration checks (docs-authoring 0.4.1: A1 / V1) not judged for tickets | A ticket's reader is carried by the tracker status — the implementer while loop-ready, the owner while a decision is pending — so a body-level declaration would restate mutable metadata, the drift the header-metadata rule already forbids. Writing a reader line into every ticket was the alternative; rejected as duplication of status. One line in guidelines.md's tracker-carried section lets the author dismiss the two residual findings without re-judging them per ticket |
| Background = premises above Done, Evidence = records last | One Background section at the end carried two roles: the premises Done assumes and the records backing claims made above. Observed 2026-08-28: docs-review on a conforming ticket flagged a load-bearing premise sitting below the Done item that depended on it — the premises-above-dependents rule (docs-authoring 0.4.1, T3). Moving the whole section up was rejected: the records it also held would then sit above the claims they serve (docs-authoring 0.4.1, T4). Splitting the roles gives each placement one section. Evidence holds records that back claims, not revision history: five audits read a retracted-options paragraph there as drafting history serving no claim above (2026-08-28), so it goes to the ticket log |

## Data Flow

- **Authoring**: user intent → installed writing skill loaded (drafting input) → guidelines.md rules applied in the main session → draft → premise audit (ticket-review agent) → findings folded back → prose self-review per the writing skill's own criteria → filed ticket.
- **Audit**: ticket (pasted draft / file path / tracker ID) → ticket-review agent (isolated context, this skill preloaded) → reads guidelines.md + checklist.md → resolves the value anchor → scores T1–T5 → findings report back to the main session.

## Constraints & Tradeoffs

- Tracker-ID input depends on the task-tracker plugin's `task.sh`; other trackers require the caller to paste the ticket body.
- Value-anchor auto-discovery is heuristic: a repository whose purpose statement lives elsewhere (wiki, external doc) rates T2 against the generic standard unless the caller passes the anchor explicitly.
- The checklist judges premises, not truth: a ticket can pass T1–T5 while being strategically wrong — that judgment stays with the human.

## History

Promoted 2026-08 from a project-local agent (`tui-game` `.claude/agents/ticket-review.md`) after the audit proved effective in that project's filing gate.
