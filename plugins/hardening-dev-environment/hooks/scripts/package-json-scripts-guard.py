#!/usr/bin/env python3
"""PreToolUse hook: blocks Edit/Write that modify package.json's "scripts" field.

The "scripts" field is a high-value supply-chain persistence vector
(`npm install` runs lifecycle hooks). File-level deny on package.json
would block legitimate dependency edits, so this hook detects "scripts"
diffs only — additions, modifications, and removals all block.

Output contract: silent exit 0 = allow; JSON with permissionDecision="deny"
on stdout = block.
"""

import json
import os
import sys


def deny(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def parse_scripts(content: str) -> dict:
    """Return the .scripts dict from a package.json string, or {} on failure."""
    try:
        data = json.loads(content)
    except json.JSONDecodeError:
        return {}
    scripts = data.get("scripts")
    return scripts if isinstance(scripts, dict) else {}


def diff_scripts(old: dict, new: dict) -> dict:
    """Return added / modified / removed entries between two scripts dicts."""
    return {
        "added": {k: v for k, v in new.items() if k not in old},
        "modified": {
            k: {"before": old[k], "after": new[k]}
            for k in new
            if k in old and old[k] != new[k]
        },
        "removed": {k: v for k, v in old.items() if k not in new},
    }


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = data.get("tool_name")
    if tool_name not in ("Edit", "Write"):
        sys.exit(0)

    tool_input = data.get("tool_input") or {}
    file_path = tool_input.get("file_path", "")
    if os.path.basename(file_path) != "package.json":
        sys.exit(0)

    # Existing content (may not exist for Write to a new file).
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            old_content = f.read()
    except FileNotFoundError:
        old_content = ""
    except OSError:
        sys.exit(0)

    # New file creation: no existing scripts to protect; allow.
    if not old_content:
        sys.exit(0)

    # Predict the post-edit content.
    if tool_name == "Write":
        new_content = tool_input.get("content", "")
    else:  # Edit
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        if old_string not in old_content:
            # Edit will fail at the tool layer; not our concern.
            sys.exit(0)
        new_content = old_content.replace(old_string, new_string, 1)

    old_scripts = parse_scripts(old_content)
    new_scripts = parse_scripts(new_content)

    if old_scripts == new_scripts:
        sys.exit(0)

    diff = diff_scripts(old_scripts, new_scripts)
    summary = json.dumps(diff, separators=(",", ":"))
    if len(summary) > 400:
        summary = summary[:397] + "..."

    deny(
        f"package.json scripts modification blocked. The 'scripts' field is a "
        f"common supply-chain persistence vector (npm install runs lifecycle "
        f"hooks). Diff: {summary}. If this change is legitimate, edit the "
        f"scripts field manually or with explicit user approval."
    )


if __name__ == "__main__":
    main()
