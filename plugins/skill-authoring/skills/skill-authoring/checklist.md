# Skill Quality Checklist

Evaluation criteria used by both the creation and review workflows.
Rate each item as **OK / NG / N/A**.

---

## Design Principles

### G: Context Design

| # | Check item |
|---|-----------|
| G1 | Skill purpose is clear (efficiency, accuracy through context separation, or session longevity) |
| G2 | Execution pattern selection is appropriate (apply the selection flow below, note the path in remarks) |
| G3 | Input context is controlled to the minimum necessary |
| G4 | No unnecessary data is wasting context during processing |
| G5 | Output to the main session is concisely controlled |
| G6 | On step failure, the skill does not act contrary to its purpose (e.g., reporting "all clear" with stale data) |

**G2 Selection Flow** (apply steps in order, note the path with arrows in remarks):

1. Requires interactive back-and-forth with user? → Yes: **Main session**
2. Need to reference main context while isolating context cost? → Yes: **context: fork**
3. Will it be executed repeatedly?
   - No → **Built-in SubAgent**
   - Yes → **Custom SubAgent** (requires definition in `.claude/agents/`. [Details](custom-subagent.md))

Remarks example: `"1.No → 2.No → 3.Yes → Custom SubAgent. Current: Built-in → NG"`

---

## Standard Rules (apply to all projects)

### S: Structure

| # | Check item |
|---|-----------|
| S1 | SKILL.md exists at the skill directory root |
| S2 | SKILL.md is 500 lines or fewer |
| S3 | References are 1 level deep max (SKILL.md → file, no further nesting) |
| S4 | Files over 100 lines have a TOC at the top |
| S5 | Relative paths are used for inter-file references within the skill |

### F: Frontmatter

| # | Check item |
|---|-----------|
| F1 | `name` is lowercase hyphen-separated and 64 characters or fewer |
| F2 | `description` is 1024 characters or fewer |
| F3 | `description` is written in third person |
| F4 | `description` includes trigger phrases |
| F5 | `name` is specific and represents the skill's function |

### C: Content

| # | Check item |
|---|-----------|
| C1 | Information is concise with no verbose explanations |
| C2 | Terminology is consistent throughout all documents |
| C3 | No time-dependent expressions ("latest", "current", etc.) |
| C4 | Procedures are written as clear, numbered steps |
| C5 | Error handling procedures are included |

---

## Recommended Practices

### D: design.md

| # | Check item |
|---|-----------|
| D1 | design.md exists in the skill directory |
| D2 | Has a `## Purpose` section |
| D3 | Has a `## Design Decisions` section in table format |
| D4 | Has a `## Data Flow` section |
| D5 | Has a `## Constraints & Tradeoffs` section |

### A: Scripts & External Integrations

> Rate as N/A for skills without scripts or external API integrations.

| # | Check item |
|---|-----------|
| A1 | Script output is in a format easily consumed by Claude |
| A2 | Data formatting and filtering are handled within the script (not delegated to the LLM) |
| A3 | Error handling is implemented in the script |
| A4 | Credential files are placed at `~/.<name>_*` (outside the skill directory) |
| A5 | `chmod 600` for credential files is documented in setup instructions |
| A6 | Data volume returned to the main session is appropriately controlled |
