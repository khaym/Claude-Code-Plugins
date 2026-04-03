# Skill Review Workflow

Process for evaluating and improving existing skills.
See [guidelines.md](guidelines.md) for shared rules.

---

## Table of Contents

1. [Load Skill](#1-load-skill)
2. [Compare Against Guidelines](#2-compare-against-guidelines)
3. [Checklist Evaluation](#3-checklist-evaluation)
4. [Create Improvement Proposals](#4-create-improvement-proposals)
5. [Output Review Report](#5-output-review-report)
6. [Implement Improvements](#6-implement-improvements)

---

## 1. Load Skill

Read all files in the target skill:

- `SKILL.md`
- `design.md` (if present)
- Script files (`.py`, `.sh`, etc.)
- Other referenced files

Also check the directory structure and note any missing or extraneous files.

## 2. Compare Against Guidelines

Compare against [guidelines.md](guidelines.md) and verify:

**Standard rules**:
- Frontmatter format (name, description)
- File structure (line limits, reference depth, path notation)
- Content quality (conciseness, consistent terminology, time-dependent language)

**Best practices**:
- design.md with recommended sections
- Token optimization patterns
- File naming conventions
- Credential file placement

**Incremental update degradation** (when reviewing skills modified over time):
- Emphasis imbalance — newly added sections disproportionately verbose?
- Content duplication — same thing stated in two places?
- Structural coherence — document reads as a unified whole?

## 3. Checklist Evaluation

Evaluate all items in [checklist.md](checklist.md).

For each item:
- **OK**: Meets the criterion
- **NG**: Does not meet the criterion (improvement needed)
- **N/A**: Not applicable (e.g., script-related items for a skill without scripts)

## 4. Create Improvement Proposals

Categorize NG items by priority:

| Priority | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Affects functionality or security | Credential exposure, exceeds 500 lines, missing frontmatter |
| **Recommended** | Improves quality or maintainability | Missing design.md, inconsistent terminology, no TOC |
| **Minor** | Nice-to-have improvements | Wording tweaks, formatting consistency |

Each proposal should include:
- Current problem
- Specific improvement
- Expected benefit

## 5. Output Review Report

Generate a report in the following format:

```markdown
# Skill Review Report: {skill-name}

## Overview
- Target: {skill-name}
- Review date: {YYYY-MM-DD}
- Execution pattern: {Main session / context:fork / Built-in SubAgent / Custom SubAgent}

## Checklist Results

### Standard Rules
| # | Item | Rating | Notes |
|---|------|--------|-------|
| S1 | SKILL.md exists | OK/NG | ... |
...

### Best Practices
| # | Item | Rating | Notes |
|---|------|--------|-------|
| D1 | design.md exists | OK/NG | ... |
...

## Improvement Proposals

### Critical
- [ ] {Proposal 1}

### Recommended
- [ ] {Proposal 2}

### Minor
- [ ] {Proposal 3}

## Overall Assessment
{Summary observations and recommended actions}
```

## 6. Implement Improvements

1. Present the review report to the user
2. Get user approval before implementing changes
3. After improvements, verify that affected checklist items now rate OK
