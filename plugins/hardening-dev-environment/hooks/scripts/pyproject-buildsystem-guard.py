#!/usr/bin/env python3
"""PreToolUse hook: blocks edits to pyproject.toml [build-system] and setup.py.

The [build-system] table selects and parameterizes the PEP 517 build backend,
which executes arbitrary Python at build/install time. setup.py is itself an
executable module run at sdist build / install time. Both are high-value
supply-chain persistence vectors.

File-level deny on pyproject.toml would block legitimate [tool.uv] / [project]
/ [project.dependencies] edits, so for pyproject.toml this hook detects only
diffs inside the [build-system] table (and any [build-system.*] sub-tables).
setup.py is treated as fully sensitive — any modification blocks.

Output contract: silent exit 0 = allow; JSON with permissionDecision="deny"
on stdout = block.
"""

import json
import os
import re
import sys

_TABLE_RE = re.compile(r"^\s*\[([^\]]+)\]\s*$")


def deny(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def extract_build_system(content: str) -> str:
    """Return the [build-system] section text (including any [build-system.*]
    sub-tables). Empty string if the table is absent."""
    out = []
    in_section = False
    for line in content.splitlines(keepends=True):
        m = _TABLE_RE.match(line)
        if m:
            name = m.group(1).strip()
            in_section = name == "build-system" or name.startswith("build-system.")
            if in_section:
                out.append(line)
            continue
        if in_section:
            out.append(line)
    return "".join(out)


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
    basename = os.path.basename(file_path)
    if basename not in ("pyproject.toml", "setup.py"):
        sys.exit(0)

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            old_content = f.read()
    except FileNotFoundError:
        old_content = ""
    except OSError:
        sys.exit(0)

    # New file creation: no existing build trust to protect; allow.
    if not old_content:
        sys.exit(0)

    if tool_name == "Write":
        new_content = tool_input.get("content", "")
    else:  # Edit
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")
        if old_string not in old_content:
            sys.exit(0)
        new_content = old_content.replace(old_string, new_string, 1)

    if basename == "setup.py":
        if old_content == new_content:
            sys.exit(0)
        deny(
            "setup.py modification blocked. setup.py executes arbitrary Python "
            "at sdist build / install time and is a common supply-chain "
            "persistence vector. If this change is legitimate, edit setup.py "
            "manually or with explicit user approval."
        )

    # pyproject.toml — only block when [build-system] section changes.
    old_bs = extract_build_system(old_content)
    new_bs = extract_build_system(new_content)
    if old_bs == new_bs:
        sys.exit(0)

    summary = json.dumps(
        {"before": old_bs[:160], "after": new_bs[:160]},
        separators=(",", ":"),
    )
    if len(summary) > 400:
        summary = summary[:397] + "..."

    deny(
        "pyproject.toml [build-system] modification blocked. The [build-system] "
        "table selects and parameterizes the PEP 517 build backend, which runs "
        f"arbitrary code at build/install time. Diff: {summary}. If this change "
        "is legitimate, edit the [build-system] table manually or with explicit "
        "user approval."
    )


if __name__ == "__main__":
    main()
