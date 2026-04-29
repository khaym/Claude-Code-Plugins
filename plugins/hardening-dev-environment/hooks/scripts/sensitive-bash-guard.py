#!/usr/bin/env python3
"""PreToolUse hook: blocks read-only Bash commands that target credential paths.

Bash subprocesses bypass `Read(...)` deny rules in .claude/settings.json per
Claude Code's permission docs. This hook is the dynamic backstop for the
C-1 rule set in hardening-claude-permissions.

Output contract: silent exit 0 = allow; JSON with permissionDecision="deny"
on stdout = block. See hooks/design.md for known bypass vectors.
"""

import json
import re
import sys

READ_ONLY = {
    "cat", "head", "tail", "grep", "egrep", "fgrep", "rgrep",
    "find", "wc", "diff", "stat", "od", "xxd", "awk", "gawk",
    "sed", "less", "more", "file", "tac", "nl", "cut", "paste",
    "sort", "uniq", "column", "pr", "fold", "strings", "hexdump",
    "base64", "tee",
}

WRAPPERS = {"timeout", "time", "nice", "nohup", "stdbuf", "sudo", "env"}

_HOME = r"(?:~|\$HOME|\$\{HOME\}|/home/[^/\s]+|/Users/[^/\s]+|/root)"

_PATH_PATTERNS = [
    r"\.env(?:\.[^\s/]+)?",
    r"\.envrc",
    _HOME + r"/\.ssh(?:/[^\s]*)?",
    _HOME + r"/\.gnupg(?:/[^\s]*)?",
    _HOME + r"/\.aws(?:/[^\s]*)?",
    _HOME + r"/\.azure(?:/[^\s]*)?",
    _HOME + r"/\.config/gcloud(?:/[^\s]*)?",
    _HOME + r"/\.config/doctl(?:/[^\s]*)?",
    _HOME + r"/\.heroku(?:/[^\s]*)?",
    _HOME + r"/\.netlify(?:/[^\s]*)?",
    _HOME + r"/\.vercel(?:/[^\s]*)?",
    _HOME + r"/\.fly(?:/[^\s]*)?",
    _HOME + r"/\.config/gh(?:/[^\s]*)?",
    _HOME + r"/\.config/glab-cli(?:/[^\s]*)?",
    _HOME + r"/\.netrc",
    _HOME + r"/\.config/git/credentials",
    _HOME + r"/\.docker/config\.json",
    _HOME + r"/\.config/containers/auth\.json",
    _HOME + r"/\.npmrc",
    _HOME + r"/\.yarnrc(?:\.yml)?",
    _HOME + r"/\.cargo/credentials(?:[^\s/]*)?",
    _HOME + r"/\.pypirc",
    _HOME + r"/\.gem/credentials",
    _HOME + r"/\.composer/auth\.json",
    _HOME + r"/\.nuget/NuGet\.Config",
    _HOME + r"/\.pgpass",
    _HOME + r"/\.my\.cnf",
    _HOME + r"/\.snowsql/config",
    _HOME + r"/\.terraform\.d/credentials\.tfrc\.json",
    _HOME + r"/\.config/pulumi/credentials\.json",
    _HOME + r"/\.kube/config",
    _HOME + r"/\.password-store(?:/[^\s]*)?",
    _HOME + r"/\.config/sops(?:/[^\s]*)?",
    _HOME + r"/\.config/age(?:/[^\s]*)?",
]

SENSITIVE_RE = re.compile(
    r"(?<![\w-])(?:" + "|".join(_PATH_PATTERNS) + r")(?![\w-])"
)

# Compound-command separators per Claude Code docs.
SEP_RE = re.compile(r"\|\||&&|\|&|[;|&\n]")


def deny(reason: str) -> None:
    """Emit a deny decision and exit cleanly."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def strip_wrappers(tokens: list) -> list:
    """Drop leading wrapper commands (timeout, sudo, etc.) and their flag args."""
    while tokens and tokens[0].split("/")[-1] in WRAPPERS:
        tokens = tokens[1:]
        # Skip flag-style args and one numeric arg (e.g. timeout 30, nice -n 5).
        while tokens:
            head = tokens[0]
            if head.startswith("-"):
                tokens = tokens[1:]
                continue
            stripped = head.replace(".", "", 1)
            if stripped.isdigit() and len(tokens) > 1:
                tokens = tokens[1:]
                continue
            break
    return tokens


def evaluate(command: str) -> str | None:
    """Return a deny reason if the command matches; None to allow."""
    for segment in SEP_RE.split(command):
        seg = segment.strip()
        if not seg:
            continue
        tokens = seg.split()
        tokens = strip_wrappers(tokens)
        if not tokens:
            continue
        cmd_name = tokens[0].split("/")[-1]
        if cmd_name not in READ_ONLY:
            continue
        rest = " ".join(tokens[1:])
        match = SENSITIVE_RE.search(rest)
        if match:
            return (
                f"Bash hardening hook: read-only command '{cmd_name}' targets "
                f"sensitive path '{match.group(0)}'. Reading credential files "
                f"via Bash bypasses Read tool deny rules in settings.json. "
                f"Refactor the task or seek explicit user approval."
            )
    return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    command = (data.get("tool_input") or {}).get("command", "")
    if not command:
        sys.exit(0)

    reason = evaluate(command)
    if reason:
        deny(reason)


if __name__ == "__main__":
    main()
