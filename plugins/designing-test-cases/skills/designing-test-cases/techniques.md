# Test Design Techniques Reference

Detailed definitions, rules, and examples for each technique.

## Table of Contents

- [Equivalence Partitioning](#equivalence-partitioning)
- [Boundary Value Analysis](#boundary-value-analysis)
- [Null / Undefined Handling](#null--undefined-handling)
- [Type Mismatch](#type-mismatch)
- [State Transition](#state-transition)
- [Combination / Interaction](#combination--interaction)
- [Error / Exception](#error--exception)

---

## Equivalence Partitioning

Divide the input domain into classes where all values in a class
are expected to produce equivalent behavior. Test at least one
representative from each class.

### Rules

1. Identify **valid classes** (accepted inputs) and **invalid classes** (rejected inputs)
2. Each class should be independent — a value belongs to exactly one class
3. One representative per class is the minimum; add more for critical classes

### How to Identify Classes

| Input type | Valid classes | Invalid classes |
|------------|-------------|-----------------|
| Numeric range [1, 100] | {1..100} | {< 1}, {> 100} |
| String enum ("A", "B", "C") | {"A"}, {"B"}, {"C"} | {any other string} |
| Boolean | {true}, {false} | {non-boolean values} |
| Array (1-10 items) | {1 item}, {2-9 items}, {10 items} | {0 items}, {11+ items} |
| Formatted string (email) | {valid format} | {missing @}, {missing domain}, {empty} |

### Example

Function: `setPageSize(size: number)` — accepts 1 to 1000.

| Class | Representative | Expected |
|-------|---------------|----------|
| Valid: small | 1 | Accepted |
| Valid: typical | 100 | Accepted |
| Valid: large | 1000 | Accepted |
| Invalid: zero | 0 | Rejected |
| Invalid: negative | -5 | Rejected |
| Invalid: over max | 1001 | Rejected |

---

## Boundary Value Analysis

Test at exact boundaries where behavior changes. Bugs cluster
at boundaries more than within equivalence classes.

### Rules

1. For each boundary, test: **on the boundary**, **one below**, **one above**
2. Apply to both sides of a range (min and max)
3. Consider the data type's own boundaries (e.g., MAX_SAFE_INTEGER)

### Boundary Types

| Type | Boundaries to test |
|------|--------------------|
| Numeric range [min, max] | min-1, min, min+1, max-1, max, max+1 |
| String length [0, maxLen] | "", 1 char, maxLen-1, maxLen, maxLen+1 |
| Array size [minLen, maxLen] | minLen-1, minLen, maxLen, maxLen+1 |
| Date range | day before start, start, end, day after end |
| Integer types | INT8: -129, -128, 127, 128 |
| Pagination | page 0, page 1, last page, last page + 1 |

### Special Boundaries

| Value | Why it matters |
|-------|---------------|
| 0 | Division by zero, falsy in JS, array index base |
| -1 | Off-by-one, unsigned underflow |
| Empty string "" | Falsy in JS, `Number("") === 0` |
| MAX_SAFE_INTEGER | 2^53 - 1, precision loss above this |
| Floating point | 0.1 + 0.2 !== 0.3 |

### Example

Function: `getPage(pageIndex, pageSize)` — 25 total rows, pageSize=10.

| Boundary | Input | Expected |
|----------|-------|----------|
| First page | pageIndex=0 | 10 rows (id 1-10) |
| Last full page | pageIndex=1 | 10 rows (id 11-20) |
| Partial last page | pageIndex=2 | 5 rows (id 21-25) |
| Beyond data | pageIndex=3 | 0 rows |
| Negative index | pageIndex=-1 | Error or 0 rows |
| Zero pageSize | pageSize=0 | Error or 0 rows |

---

## Null / Undefined Handling

Null-related bugs are among the most common. Systematically test
all null/undefined scenarios.

### Rules

1. For each parameter, test: null, undefined, and the type's "empty" value
2. Distinguish between **nullable** (null is valid) and **non-nullable** (null is an error)
3. Test missing properties (key not present in object) separately from null values

### Checklist

| Scenario | Input | Consider |
|----------|-------|----------|
| Explicit null | `null` | Is it nullable? Should it be accepted or rejected? |
| Undefined | `undefined` | Same as null? Different handling? |
| Empty string | `""` | Is it treated as null? As a valid value? |
| Empty array | `[]` | Valid empty collection or error? |
| Empty object | `{}` | Missing required properties? |
| Missing property | `{ a: 1 }` (b is missing) | Does it default? Throw? Return undefined? |
| Nested null | `{ a: { b: null } }` | Deep property access without null check? |

### Example

Function: `editCell(rowIndex, column, value)` — column is non-nullable UTF8.

| Scenario | Input | Expected |
|----------|-------|----------|
| Valid value | value="hello" | Accepted |
| Null on non-nullable | value=null | Validation error |
| Undefined value | value=undefined | Validation error |
| Empty string on non-nullable | value="" | Accepted (empty string is a valid string) or rejected? Clarify spec |
| Column name null | column=null | Error |
| Nonexistent column | column="nonexistent" | Error |

---

## Type Mismatch

Test what happens when a value of the wrong type is provided.
Especially important in dynamically typed languages and at
system boundaries (user input, API responses, message passing).

### Rules

1. For each parameter, test with at least one wrong type
2. Pay attention to implicit type coercion rules of the language
3. Serialization boundaries (JSON.parse, message passing) lose type information

### Common Coercion Traps (JavaScript)

| Expression | Result | Trap |
|-----------|--------|------|
| `Number("")` | `0` | Empty string becomes zero, not NaN |
| `Number("123abc")` | `NaN` | Partial numeric string |
| `Number(true)` | `1` | Boolean coercion |
| `Number(null)` | `0` | Null becomes zero |
| `Number(undefined)` | `NaN` | Undefined becomes NaN |
| `String(null)` | `"null"` | Not empty string |
| `JSON.parse(json)` | loses BigInt, Date, undefined | Serialization boundary |

### Checklist

| Expected type | Test with |
|--------------|-----------|
| number | string, boolean, null, NaN, Infinity, string-number ("42") |
| string | number, boolean, null, object |
| boolean | 0, 1, "", "false", null |
| array | null, object, string |
| object | null, array, primitive |

---

## State Transition

Identify the states a system can be in and the transitions between them.
Test valid transitions, invalid transitions, and sequences.

### Rules

1. Draw or enumerate the state model: states + events + transitions
2. Test every valid transition at least once
3. Test at least one invalid transition per state (event that shouldn't be possible)
4. Test multi-step sequences, especially cycles

### How to Identify States

Look for:
- Boolean flags (isDirty, isEditing, isLoading)
- Enum/mode values (activeTab: "data" | "schema")
- Lifecycle stages (created → initialized → ready → disposed)
- Undo/redo stacks (empty, has items, at save point)

### Example

Document edit state: Clean → Dirty → Saved → Clean.

| Sequence | Expected |
|----------|----------|
| edit → isDirty=true | Valid |
| edit → save → isDirty=false | Valid |
| edit → undo → isDirty=false | Valid (back to original) |
| edit → undo → redo → isDirty=true | Valid |
| save (no edits) → isDirty=false | No-op, still clean |
| undo (no edits) → returns false | Nothing to undo |
| edit → save → edit → undo → isDirty=true | Dirty relative to save point |

---

## Combination / Interaction

Test how multiple inputs or operations interact. Individual inputs
may be valid, but their combination may trigger bugs.

### Rules

1. Identify parameters that interact (affect each other's behavior)
2. Use pairwise coverage as a minimum: every pair of parameter values appears at least once
3. Test order-dependent operations in both orders

### Common Interaction Patterns

| Pattern | Example | What to test |
|---------|---------|-------------|
| Filter + Pagination | Filter reduces rows, pagination must adjust | Filter → page 2 → no longer exists |
| Edit + Filter | Edit a filtered row | Correct row index mapping |
| Multiple filters | AND combination | Each filter alone, all combined, conflicting filters |
| Sort + Edit | Edit then sort, sort then edit | Data integrity after reorder |
| Undo + Page change | Edit on page 1, go to page 2, undo | Undo applies to correct page |

### Example

Filter + Pagination + Edit interaction:

| Scenario | Steps | Expected |
|----------|-------|----------|
| Edit filtered row | Apply filter → edit visible row | Correct original row is modified |
| Page after filter | Apply filter reducing to 3 rows → page 2 | Empty or auto-reset to page 1 |
| Clear filter after edit | Edit filtered row → clear filter | Edit persists in full data |
| Undo during filter | Edit → apply filter → undo | Edit is undone regardless of filter state |

---

## Error / Exception

Test error paths to ensure failures are handled gracefully.

### Rules

1. For each operation, identify what can go wrong
2. Test that errors produce meaningful messages (not generic "Error")
3. Test that errors don't corrupt state (partial updates, dangling locks)
4. Test recovery: can the user continue after an error?

### Error Categories

| Category | Examples |
|----------|---------|
| Validation error | Invalid input format, out-of-range value, type mismatch |
| Resource error | File not found, network timeout, permission denied |
| Concurrency error | Stale data, race condition, double submit |
| Overflow/underflow | Integer overflow, stack overflow, memory limit |
| Partial failure | 3 of 5 items saved, transaction half-committed |

### Checklist

| Scenario | Test |
|----------|------|
| Invalid input | Is the error message specific and actionable? |
| After error | Can the user retry or continue without refresh? |
| State after error | Is state consistent (no partial mutations)? |
| Error propagation | Does the error reach the UI? Not silently swallowed? |
| Multiple errors | Second error while first error is displayed? |
