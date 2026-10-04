# Design Doc Format Checklist

Binary checks of whether a design lets its implementer understand the purpose and the intent behind each rule, and choose the means without guessing. Scored by the `design-doc-review` agent, and usable by a writer checking a closed design.
Rate each item as **OK / NG / N/A**, judging from the three documents alone. For each NG, consult the matching section in [guidelines.md](guidelines.md) — the Section column names it.

Each check restates one rule of guidelines.md as a yes/no question about the documents; a check adds no rule of its own. Contradictions in content — two essentials that fight, a decision the flow does not carry out — are not judged here: the walkthrough is where they are found.

Three checks follow the chain from purpose to means across the documents — BR7, BR5, D7: each rule's intent connects a purpose to its specification, its grounds lead to a purpose, decision, and fact the Design Doc holds, and each essential's intent leads back to a listed purpose. They judge whether the chain is closed within the documents, not whether the purpose is the right one; that judgment is the requester's.

A statement that fails S1 is sometimes a rule that dropped its intent: with the intent restored, it states what a record must satisfy or an order the system must impose. The direction for such a statement is to restore the intent and write it in Business Rules, not to delete it — a specification without the intent is a copy of the code ([Business Rules](guidelines.md#business-rules)).

The checks judge a design that has reached its close — walkthrough done, undecided items given their options. Run over an earlier draft, D9 and D11 are expected to fail until those stages are written.

Four layers, one per scope:

- **S** — the document set: what goes where, which way references point
- **D** — the Design Doc
- **DD** — the Data Dictionary
- **BR** — the Business Rules

The supplements are the ones the Design Doc's supplement list names, at the locations it gives. When a supplement is not listed, or not found at its listed location, its layer rates N/A with that reason, and S4 carries the finding.

---

## S: Document set

| # | Check item | Section |
|---|-----------|---------|
| S1 | No document states how a component does its work inside — branches, internal ordering, how a write is made atomic, how a directory is created, how a hash is computed, the order a cleanup walks; the documents hold flow and rules only | The one question; The documents hold the flow and the rules; code holds the procedure |
| S2 | References point one way — Business Rules → Data Dictionary → Design Doc: the Data Dictionary cites no Business Rule, and the Design Doc's only pointer to a supplement is its supplement list, which never cites a supplement's content | Three documents |
| S3 | Every rule statement lives in Business Rules and nowhere else: the Design Doc carries essentials, not rule statements, and Data Dictionary entries point at records, not rules (when or how often a record is written, or the condition under which it must not be deleted, is not in its entry) | Business Rules; Data Dictionary entry |
| S4 | The supplement list registers every supplement — the two and any the project added — with the question it answers and its location, and each listed supplement exists at that location | Three documents; Design Doc items (Indexes) |

## D: Design Doc

| # | Check item | Section |
|---|-----------|---------|
| D1 | The ten items appear as headings in this order: Purpose, Facts, Flow, Records, Keys, Essentials, Decisions, Walkthrough, Boundary, Indexes | Design Doc items |
| D2 | Purpose names who gains what and who is deliberately not served, and nothing else — no means | Design Doc items (Purpose) |
| D3 | Facts give each premise with its source (observation record, real data, real code), marked apart from decisions; a provisional premise is marked as such | Design Doc items (Facts); Design derives rules from the purpose |
| D4 | Flow shows, from the user's side, how the components line up and which records pass between them | Design Doc items (Flow) |
| D5 | Records lists every record the system manages — including records written outside the system that it only reads — with its role, where it lives, and its lifetime; Keys states which fields join which records | Design Doc items (Records, Keys) |
| D6 | Detail the walkthrough does not need sits in a supplement, not in the Design Doc — e.g. a record's field definitions belong to its Data Dictionary entry | Three documents (the walkthrough test) |
| D7 | Essentials give, for each purpose the Purpose item names, purpose → intent → the states records must satisfy, in present tense; each intent says what that purpose's gainer gets, and each state follows from its intent — each states what holds, not why it was decided | Design Doc items (Essentials, Decisions); Design derives rules from the purpose |
| D8 | Each decision is numbered and holds the adopted option, its reason, and the rejected options with their reasons, kept separate from the essentials | Design Doc items (Decisions) |
| D9 | Walkthrough passes one representative case through the flow using the essentials alone, and records the steps, the undecided items and contradictions found, and what they changed | Design Doc items (Walkthrough); Contradictions show in a walkthrough, not in a list |
| D10 | Boundary states what the system does not do and the line to neighboring systems; when the work is cut into several stories, it names which stories and which decisions each implements | Design Doc items (Boundary) |
| D11 | Each undecided line holds the question, the stage where it arose, two options, the recommended one and why, and the requester's words verbatim while the answer is pending; no line waits on an observation (that is provisional), and no decided line remains | Two indexes |
| D12 | Each provisional line holds the value, where it was decided, and the observation that will trigger revising it | Two indexes |
| D13 | When Boundary lists the stories the work is cut into, the undecided index is empty | Two indexes; Design Doc items (Boundary) |
| D14 | The Design Doc holds no history (when, from what, or on whose word something changed) and no story order, dependencies, or work content | Present tense only |

## DD: Data Dictionary

| # | Check item | Section |
|---|-----------|---------|
| DD1 | One entry per record, as labeled lines under the record's heading, with the six items — record name (the same as in the Design Doc's record list), fields and definitions, writer, location, keys, lifetime — and no identity item | Data Dictionary entry |
| DD2 | Each field is one line with its meaning, or the entry points to an existing machine-readable schema | Data Dictionary entry |

## BR: Business Rules

| # | Check item | Section |
|---|-----------|---------|
| BR1 | Each rule has the four items: identifier, statement, bound record, grounds | Business Rules |
| BR2 | Each identifier is lowercase letters, digits, and hyphens — two to four words naming the state the rule establishes or the order it imposes, with no chapter numbers | Business Rules |
| BR3 | Each statement is one sentence of the form "so that <who> can <what>, <this state holds / this order is kept>", with no separate reason line | Business Rules |
| BR4 | Each rule names the record (or document) it binds, by its name in the Data Dictionary | Business Rules |
| BR5 | Grounds are the purpose served, the decision rested on, and the fact behind it — never another rule and never an undecided item; the purpose is one the Design Doc lists, the decision one its Decisions item holds, and the fact one its Facts item gives | Business Rules |
| BR6 | Rules are grouped by the purpose they serve, in the order the Design Doc lists its purposes | Business Rules |
| BR7 | Each rule is the intent connecting purpose and specification: given the purpose in its grounds, its intent says why this specification (the state that holds or the order kept) — no specification stands without an intent that explains it (a copy of the code), and no intent stands without a specification (a wish) | Business Rules; Design derives rules from the purpose |
