# coding-guideline Design Doc

## Purpose

A story implemented with LLM assistance fails its requester in two ways that review keeps catching late: it drifts from the goal, and it becomes hard to change (the two roots are in guidelines.md, Two ways off the purpose). In one host project, nine autonomous laps produced 33 restated Business Rules and 8 tests whose fixtures held states production never holds. The development cycle had only a comment rule on the code side; nothing said how tests, code, and comments are derived from the input. This skill is that discipline: correspondence rules against the first root, structure rules against the second, and one method — Data-Oriented Programming — that builds the structure from the input.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| The purpose is the frame: the input is what was decided toward it, the rules are constraints, the means are the author's | A guideline read as "transcribe the design into code" lowers the author to a copier and produces a mechanical one-to-one mapping (one type per entry, one function per flow step) that serves the documents, not the purpose. Stating the freedom explicitly, and sending an input that works against the purpose back to the requester, keeps an LLM author at the purpose's altitude. Rejected: a stepwise order of work — it read as a transcription procedure; only "find the home first" survives as a required step |
| Two roots, not one: the wrong source (code-anchored) and no structure | Folding both into "the output's shape was taken from the code" misnames the second: a faithful transcription of the input still piles rules in callers when nothing says where they go. Naming the roots separately is what lets the guideline stay at a few rules — each root requires its own antibody, and a defect is named by the rule it breaks instead of getting a rule of its own |
| General rules first, then one method; the structure rules are stated without the method's vocabulary | The rules are what must hold and survive a change of method; the method is one way to reach them. A reader who rejects Data-Oriented Programming still reads what must hold. Rejected: a per-defect rulebook (never closes), and the method alone (a reader cannot tell what the method is for) |
| The method is Data-Oriented Programming v1.1 as Inside Java states it — four principles, verbatim — written in language-neutral terms, and it is the default, not a requirement: the structure rules are what the reviewer judges by | One named source keeps the method from drifting into the author's taste; v1.1 folds "validate at the boundary" into "make illegal states unrepresentable" and adds the separation of operations, which is the principle that produces homes. The host projects write Python while the source is Java, so the guideline uses terms both have (immutable record type, closed set of alternatives, pure function) and leaves per-language forms to the host |
| Find the home first is the one required step | The two misjudgments this prevents — believing a home does not exist, and not noticing a sibling that already does the same — both come from writing before searching. Searching by location as well as by name covers the case where a renamed term hides the home. The project's development cycle has its own observation gate at lap scope; this one is per record and Business Rule, and the guideline does not assume the cycle is installed |
| "Home" is the unit of the structure rules; "no structure" is the root | A home is the product of a structure — data and operations apart, one operation changing a record's state — so a record's home and a Business Rule's home coincide, and a Business Rule maps to the home's operation on its bound record in one line. Saying "behavior has no home" as the root names the symptom |
| A comment carries what only the author or the ticket knows; three typical kinds; two required references (Business Rule identifier, provisional origin); no restatement of a function's inputs and outputs | The earlier criterion, "a judgment with no home goes to a comment", sent too much to comments. The test is whether a reader of the committed code, tests, and design can reconstruct the intent; a ticket is not committed, so what lives only there needs a comment. A docstring that restates the signature doubles the function's home and doubles every change |
| Existing code is a premise, not an input; the discipline applies to what the change touches | The code is changeable, so it cannot constrain the input; it is read to know the starting point. A gap outside the change is recorded, and the development cycle decides when it is fixed — otherwise every change grows into a sweep |
| References point from code to design only; the design skill never reads this guideline | Designs are judged in prose by the requester and must not bend toward one implementation method |
| No checklist and no review agent | The built-in code review cannot be replaced by a plugin; the development cycle hands the diff to it with the guideline's rules, and the reviewer's pass in SKILL.md points at the rule tables as the checklist. A separate checklist would be a second home for the rules; it is added only when a review path exists that reads a checklist and nothing else |
| Shipped as its own plugin, listed among the development cycle's default tools | Same shape as the design skill: the cycle names it as a default and reports when it is missing; projects without the cycle can still install it alone |

## Data Flow

Input (Design Doc, Data Dictionary, Business Rules — or a ticket's purpose and success criteria, from which the author writes down the decisions the documents would have carried) → find the home for each record and Business Rule (one, none, or several) → the author builds under the structure rules with the element table as reference, means chosen for the purpose: records as immutable types, operations as pure functions with side effects at the homes' exits, Business Rules in types or in the homes' operations → tests pinning one Business Rule or criterion each → comments for the intent nothing committed says. Review branch: the diff is checked against the same rules, correspondence rules first.

## Constraints & Tradeoffs

- The rules were derived from one host project's lap log (nine laps, 377 lines, 2026-09) and are verified against its defect classes. Whether an implementation written under the guideline avoids them is observed in later laps, by whether the same defect-class slugs recur in that log; until the first such lap is logged, the table below is the only evidence. The eighth class has no slug and is outside that check; it is seen only when a lap's judgment line names a failure's origin.
- The method is written for systems that pass records between components. A story with little record state gets the correspondence rules and the comment rule; the element table has little to say.
- "Find the home first" counts hits; it does not decide what counts as the same record under a different name. That remains the author's judgment, informed by location.
- Delivery to an implementer agent (preload versus invoke at the writing stage) is decided by the development-cycle wiring, not here.

## Defect classes the rules cover

The eight classes observed in the host project's lap log, and the rule each breaks. Every class being derivable from the rules is the check the first release (0.1.0) was closed on.

| Defect class (lap-log slug) | Rule | Also built by |
|---|---|---|
| Record read or written outside its home (`data-homes-net-gaps`) | One truth, one point of change | Model data immutably and transparently |
| Same answer derived in two places (`zero-cost-literal`, `stat-after-draw`) | One derivation | Model the data, the whole data, and nothing but the data |
| Business Rule text restated outside its home (`rule-duplication`) | Business Rules cited, not restated; Business Rule beside its mechanism | Separate operations from data |
| Design term paraphrased in code (`term-single-meaning`) | Terms from the input | — |
| Partial key match on reuse (`reuse-without-identity-check`) | Identity as the input defines it | — |
| Persisted before validated, orphans left (`write-before-validate`, `partial-persistence-orphans`) | Check, then write | Separate operations from data |
| Fixture holding a state production never holds (`implementer-test-premise`) | Test premises from the record's definition | Make illegal states unrepresentable |
| Failure handled without judging its origin (two judgment lines, no slug) | Failure judged by origin | — |
