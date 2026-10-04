# design-doc-review Design Doc

## Purpose

A design is the input to implementation: it must give the implementer the purpose and the intent behind each rule, so that means are chosen from them rather than guessed or read off the code. A writer cannot see where their own design fails at this — they know what each section was meant to say, so a rule whose intent was dropped, or a Design Doc crowded with field definitions and story order, still "reads fine" from inside. This agent supplies the missing reader: the implementer, in an isolated context that knows only the documents. It reports, check by check, where that reader would have to guess, before the guess is made in code.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Custom SubAgent, read-only toolset (Read, Grep), no Bash or Glob | The audit's value is the cold context; editing rights would blur reviewer and writer. Unlike ticket-review there is nothing to run — no tracker to query — so Bash is left out. Supplement discovery forbids searching by file name, so Glob has no use; Read tells whether a resolved location exists. Grep serves cross-document checks within the documents (a record name across them) |
| Preloads `design-doc-authoring` via `skills:`, criteria read at runtime | guidelines.md and checklist.md stay the single source of truth; the agent verifies the preload at startup and refuses to audit without it |
| The question is the implementer's — can the purpose and intent be understood and the means chosen without guessing; checklist.md is the instrument, and contradictions in content are the walkthrough's to find | Reduced to conformance, the audit passes a design whose every slot is filled while its rules are specifications with no intent behind them. One finding class per agent keeps reports actionable. Whether two essentials fight needs the walkthrough the writer runs with the requester, not a conformance check |
| Supplements found only through the supplement list's locations, resolved against the Design Doc's directory and then each ancestor, nearest first | One discovery path keeps findings reproducible: two runs on the same documents read the same files. It also turns a missing location into a finding instead of something the agent silently works around. The project root is always an ancestor of the Design Doc, while the working directory is whatever the caller's session has (a host may start its sessions in a subdirectory), so resolution does not depend on it. The agent does not judge the form of a location that resolves. Rejected: searching for likely file names — a match by name may be a different document, and the audit would then pass a Design Doc whose reader cannot find its supplements |
| Judge from the documents only — no other files, conversation, code, or git history | The format is meant to be judgeable by a reader holding only the documents; a check that needs anything else is N/A with that reason, which shows where the documents fall short |
| Output shape mirrors docs-review, plus a Documents block | The main session already reads sibling findings in this shape. The Documents block names each supplement's resolution so a missing list, a missing location, or a supplement not found is visible even when it costs only one check |
| `model: opus` | Same rationale as ticket-review and docs-review: telling flow from procedure, or an essential from a rearranged decision, is judgment. Opus holds it regardless of the session's model. Sonnet was the cheaper alternative, rejected because a gate audit whose judgment degrades stops working as a defense layer. Where an organization's `availableModels` allowlist blocks opus, the agent runs on the inherited model |
| `maxTurns: 20` as a runaway guard | The documents, the two criteria files, and a few cross-document Greps fit well inside it |

## Data Flow

Design Doc path → read the Design Doc → resolve supplements from its supplement list (the Design Doc's directory, then each ancestor; else not found) → read each found document once → score S/D/DD/BR against checklist.md → findings report (documents resolved, verdicts, NG rationales and directions, N/A reasons) → main session.

## Constraints & Tradeoffs

- Mapping headings written in another language to the guidelines' items by role is a judgment, not a literal match.
- Sorting a statement as flow, rule, or procedure (S1, S3, D6), and judging whether a state follows from its intent or a rule matches an essential (BR7, D7), are judgments the skill's guidelines calibrate with examples; two runs may differ at the margin.
- Findings are advisory; the agent never blocks anything mechanically — the main session and the human decide.
