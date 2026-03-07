# test-case-design Design Doc

## Purpose
Provide a systematic framework of test design techniques to prevent gaps
in test coverage. Based on established testing concepts (equivalence partitioning,
boundary value analysis, state transition testing, etc.) rather than
implementation details, making it compatible with TDD where tests are
written before code.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Main session execution | Requires interactive dialogue: understand requirements, propose perspectives, refine with user feedback |
| Input is spec/types, not code | TDD-compatible: test cases are designed from requirements and type definitions, not implementation |
| Generic test design techniques | Based on established testing theory; reusable across projects and tech stacks |
| Observation checklist, not code generation | Test code generation is handled by the existing TDD process; the gap is in perspective coverage |
| Two modes: new test design + existing test review | "Design tests for this spec" and "are these tests sufficient?" |
| Freedom level: High | Text-based guidance with checklist; no rigid templates, allowing adaptation to any context |

## Data Flow

```
Input: Specification, requirements, type definitions, or interface contracts
  ↓
Step 1: Identify testable aspects — parameters, types, states, constraints
  ↓
Step 2: Apply test design techniques — generate candidate test cases
  ↓  - Equivalence partitioning
  ↓  - Boundary value analysis
  ↓  - Null/undefined handling
  ↓  - Type mismatch
  ↓  - State transition
  ↓  - Combination / interaction
  ↓  - Error / exception
  ↓
Step 3: Present test case matrix (perspective × input × expected result)
  ↓
(Review mode) Compare matrix against existing tests → identify gaps
```

## Constraints & Tradeoffs

- Does NOT generate test code (delegates to TDD workflow)
- Does NOT enforce a specific test framework
- Techniques are general-purpose; domain-specific edge cases may need
  user input to surface
- Review mode requires reading existing test files, which increases
  context usage but is necessary for gap analysis
