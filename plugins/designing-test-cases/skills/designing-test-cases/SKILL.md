---
name: designing-test-cases
description: Guides systematic test case design using established testing techniques. Use when writing new tests, designing test cases, reviewing existing test coverage, checking for missing test perspectives, or when you hear "test cases", "test coverage", "what should I test", "are these tests enough", "boundary values", or "edge cases".
---

# Test Case Design

Systematic test case design guidance based on established testing techniques.
Works with any tech stack and is TDD-compatible (spec-driven, not code-driven).

## Table of Contents

- [Intent Detection](#intent-detection)
- [New Design Workflow](#new-design-workflow)
- [Review Workflow](#review-workflow)
- [Quick Reference: Technique Summary](#quick-reference-technique-summary)

## Intent Detection

| Intent | Example triggers | Action |
|--------|-----------------|--------|
| **New test design** | "Design test cases for X", "What should I test?" | Follow [New Design Workflow](#new-design-workflow) |
| **Existing test review** | "Are these tests enough?", "Review test coverage" | Follow [Review Workflow](#review-workflow) |
| **Technique lookup** | "Boundary value examples", "How to test null handling" | Refer to [techniques.md](techniques.md) |

---

## New Design Workflow

Use when test cases need to be designed for a new feature or function.

### Step 1: Identify Testable Inputs

Gather from the specification, requirements, or type definitions:

- **Parameters**: names, types, constraints (range, format, length)
- **State**: initial conditions, preconditions, mutable state
- **Dependencies**: external inputs, configuration, environment
- **Output**: return values, side effects, error signals

Ask the user to clarify if the spec is ambiguous or incomplete.

### Step 2: Apply Test Design Techniques

For each testable input, apply the techniques from [techniques.md](techniques.md)
in this order of priority:

| Priority | Technique | What it catches |
|----------|-----------|-----------------|
| 1 | Equivalence Partitioning | Missing value classes (valid/invalid groups) |
| 2 | Boundary Value Analysis | Off-by-one, range edge errors |
| 3 | Null / Undefined Handling | Missing null checks, nullable confusion |
| 4 | Type Mismatch | Wrong type passed, implicit coercion bugs |
| 5 | State Transition | Invalid state sequences, missing transitions |
| 6 | Combination / Interaction | Multi-parameter interactions, AND/OR logic |
| 7 | Error / Exception | Unhandled errors, missing error paths |

Not all techniques apply to every input. Skip those that don't apply.

### Step 3: Build Test Case Matrix

Present results as a table:

```
| # | Technique | Perspective | Input | Expected Result |
|---|-----------|-------------|-------|-----------------|
| 1 | Boundary  | Min value   | 0     | Accepted        |
| 2 | Boundary  | Below min   | -1    | Rejected        |
| ...                                                    |
```

Group by technique, then by testable input. Mark high-risk cases.

### Step 4: Confirm with User

- Present the matrix and ask for feedback
- Are there domain-specific edge cases not covered?
- Are any perspectives unnecessary for this context?
- Adjust and finalize before moving to test implementation

---

## Review Workflow

Use when existing tests need to be evaluated for coverage gaps.

### Step 1: Read Existing Tests

Read the test file(s) and catalog what is currently tested.
Build a list of covered perspectives.

### Step 2: Identify the Specification

Determine what the code under test is supposed to do:
- Read the spec/requirements if available
- Read type definitions, interfaces, or function signatures
- Ask the user to clarify the intended behavior if needed

### Step 3: Generate Full Matrix

Apply the New Design Workflow (Steps 1-3) against the specification
to produce a complete test case matrix.

### Step 4: Gap Analysis

Compare the full matrix against the covered perspectives:

```
| # | Perspective       | Status  | Notes                    |
|---|-------------------|---------|--------------------------|
| 1 | Min boundary      | Covered | test line 42             |
| 2 | Below min         | MISSING | No test for negative     |
| 3 | Null input        | Covered | test line 58             |
| ...                                                        |
```

Present MISSING items as actionable recommendations.

---

## Quick Reference: Technique Summary

Below is a brief summary. See [techniques.md](techniques.md) for
detailed definitions, rules, and examples.

### Equivalence Partitioning
Divide inputs into classes that should behave the same.
Test one representative from each class.

### Boundary Value Analysis
Test at the exact boundary, one below, and one above.
Apply to: numeric ranges, string lengths, array sizes, dates.

### Null / Undefined Handling
Test: null, undefined, empty string, empty array, missing property.
Consider: nullable vs non-nullable, optional vs required.

### Type Mismatch
Test: wrong type for each parameter (string where number expected, etc.).
Consider: implicit coercion (Number("") === 0), stringified numbers.

### State Transition
Identify states and valid transitions. Test:
valid sequences, invalid sequences, repeated transitions.

### Combination / Interaction
Test: multiple parameters interacting, AND/OR conditions,
order-dependent operations, concurrent modifications.

### Error / Exception
Test: invalid input, resource unavailable, timeout,
partial failure, error message content.
