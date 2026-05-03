# hardening-overview Design Doc

## Purpose

Provide a single, discoverable entry point for `hardening-dev-environment`. This skill owns the architectural overview, runs an inspection of the current state, and routes the user to the layer skill they actually need. It does not apply any layer itself.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Overview as a discoverable skill, not a README | A README in the plugin directory does not surface in Claude Code skill discovery. A skill with appropriate trigger phrases is reachable via natural-language queries ("set up hardening", "harden dev environment") |
| Inspection + routing, not application | If this skill applied layers itself, it would duplicate logic from each layer skill. Single source of truth lives in each layer skill; the overview only inspects and routes |
| State classification per layer (applied / partial / unapplied / N/A) | Two-state classification loses information when a project has some but not all rules in a layer; "partial" directs the user to focus on the gap |
| Use-case-driven recommendations | The base setup order is the same for all plans, but use cases (CI-only, plugin-authoring, production-touching) need overlays on top. The skill collects plan tier and use case so it can route accurately |
| Defense Map lives here, not in `hardening-untrusted-content` | Self-containment principle: a skill should not own architecture for layers it does not implement |
| Hooks listed in the map but not as separate skills | Hooks auto-activate when the plugin is enabled; they are operationally distinct from skills the user invokes. Listing them clarifies what comes "for free" with the plugin |
| Overview does not auto-invoke other skills | Hand-off via skill name lets the user verify the recommendation before applying. Auto-chaining would amplify any misjudgment in the inspection step |
| Freedom level: Medium | Inspection is fixed (specific jq queries); recommendations have branches based on plan tier and use case |

## Data Flow

```
Input: project root (any state — `.claude/`, package.json optional)
  ↓
Step 1: Inspect — jq settings.json + package.json
                  treat absent files as "unapplied", do not fail
  ↓
Step 2: Build state matrix per layer
  ↓
Step 3: Confirm plan tier + use case (interactive Q&A)
  ↓
Step 4: Present map (state column) + recommended setup order
  ↓
Step 5: Hand off — user picks layer, invokes that skill explicitly
```

## Constraints & Tradeoffs

- Inspection is best-effort. A user may have hardening logic outside
  the patterns this skill checks (e.g., custom deny rules tailored
  to their stack); those will appear as "partial" or "unapplied"
  even if they cover the same threats
- Plan-tier branching depends on user self-report. The skill cannot
  detect the session's plan or model directly
- The Defense Map must be kept in sync as layer skills evolve. When a
  layer skill changes its rule set or scope, the corresponding row in
  this skill must be updated. This is the price of single ownership
