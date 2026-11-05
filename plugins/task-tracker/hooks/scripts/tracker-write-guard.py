#!/usr/bin/env python3
"""PreToolUse hook: blocks writes to the tracker's index and counter outside task.sh.

task.sh is the only writer of .tasks/tasks.tsv and .tasks/.counter: it keeps
IDs, the column count, and UPDATED consistent, and only its `add` advances the
counter. A row appended by hand leaves the counter behind, and the next `add`
hands out an ID that already exists. Details (.tasks/details/<id>.md) stay
free to edit.

Bash commands are judged by their write shapes only (redirections, tee,
sed -i, the mv/cp destination), never by mentioning a file name, so reads
with grep/awk and task.sh calls whose arguments quote `>> tasks.tsv` pass.
Heredoc bodies and quoted text are never targets. A target resolves against
the payload's cwd as moved by literal `cd`s earlier in the same command (a
`cd` inside `( ... )` ends at its closing parenthesis); when
that base is unknown (no cwd, a `cd "$X"`), a bare tasks.tsv or .counter
counts as protected.

It is a guard rail for those common write shapes, not a lock: other writers
(another program, a wrapper, a script) pass, and `task.sh add` still catches
a counter left behind by them.

Output contract: silent exit 0 = allow; JSON with permissionDecision="deny"
on stdout = block. A payload or command this hook cannot parse is allowed.
"""

import json
import os
import re
import sys

PROTECTED_NAMES = {"tasks.tsv", ".counter"}
TRACKER_DIR = ".tasks"

# Longest first, so `>>` is not read as two `>`.
OPERATORS = sorted(
    ["&>>", "<<-", "<<<", ">>", ">|", ">&", "&>", "<<", "<&", "<>",
     "&&", "||", "|&", ";;", ">", "<", "|", "&", ";", "(", ")"],
    key=len, reverse=True,
)
SEPARATORS = {"&&", "||", "|&", ";;", "|", "&", ";", "(", ")", "\n"}
HEREDOCS = {"<<", "<<-"}
ASSIGNMENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
NOT_LITERAL = set("$`*?[")
# Only the escapes that can change where a word ends or what it names; the
# value matters only when the word is a write target.
ANSI_C_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", "'": "'", '"': '"'}


class Op(str):
    """An unquoted shell operator; a plain str token is a word."""


def expand_home(path: str, home) -> str:
    if home and (path == "~" or path.startswith("~/")):
        return home + path[1:]
    return path


# base is the directory the target is relative to, or None when it cannot be
# known (no cwd in the payload, a cd to a non-literal operand). Then a bare
# name is protected too: it may well be run from inside .tasks.
def is_protected(target: str, base, home) -> bool:
    path = expand_home(target, home)
    if base is not None:
        path = os.path.join(base, path)
    parent, name = os.path.split(os.path.normpath(path))
    return name in PROTECTED_NAMES and (
        os.path.basename(parent) == TRACKER_DIR or parent == ""
    )


def cd_base(words: list, base, home):
    operands = [w for w in words[1:] if w not in ("-L", "-P", "-e", "-@", "--")]
    if not operands:
        return home
    dest = operands[0]
    if dest == "-" or NOT_LITERAL & set(dest):
        return None
    dest = expand_home(dest, home)
    if os.path.isabs(dest):
        return os.path.normpath(dest)
    if base is None or dest.startswith("~"):
        return None
    return os.path.normpath(os.path.join(base, dest))


# Not shlex: in POSIX mode it returns a quoted ">>" as the same token as the
# operator, and it reads heredoc bodies as commands. Raises ValueError on an
# unterminated quote or heredoc, which main() turns into an allow.
def tokenize(command: str) -> list:
    tokens: list = []
    pending_heredocs: list = []  # (delimiter, strip_tabs) awaiting their body
    word: list = []
    in_word = False
    i, n = 0, len(command)

    def end_word() -> None:
        nonlocal in_word
        if in_word:
            tokens.append("".join(word))
            word.clear()
            in_word = False

    while i < n:
        c = command[i]
        if c == "$" and command.startswith("$'", i):
            i += 2
            while i < n and command[i] != "'":
                if command[i] == "\\" and i + 1 < n:
                    word.append(ANSI_C_ESCAPES.get(command[i + 1], command[i:i + 2]))
                    i += 2
                else:
                    word.append(command[i])
                    i += 1
            if i >= n:
                raise ValueError("unterminated ANSI-C quote")
            in_word = True
            i += 1
        elif c == "'":
            close = command.find("'", i + 1)
            if close < 0:
                raise ValueError("unterminated single quote")
            word.append(command[i + 1:close])
            in_word = True
            i = close + 1
        elif c == '"':
            i += 1
            while i < n and command[i] != '"':
                if command[i] == "\\" and i + 1 < n and command[i + 1] in '"\\$`':
                    i += 1
                word.append(command[i])
                i += 1
            if i >= n:
                raise ValueError("unterminated double quote")
            in_word = True
            i += 1
        elif c == "\\":
            if i + 1 < n and command[i + 1] != "\n":
                word.append(command[i + 1])
                in_word = True
            i += 2
        elif c == "#" and not in_word:
            while i < n and command[i] != "\n":
                i += 1
        elif c == "\n":
            end_word()
            tokens.append(Op("\n"))
            i += 1
            for delimiter, strip_tabs in pending_heredocs:
                while True:
                    if i >= n:
                        raise ValueError("unterminated heredoc")
                    eol = command.find("\n", i)
                    eol = n if eol < 0 else eol
                    line = command[i:eol]
                    i = eol + 1
                    if (line.lstrip("\t") if strip_tabs else line) == delimiter:
                        break
            pending_heredocs.clear()
        elif c in " \t":
            end_word()
            i += 1
        elif c in "<>&|;()":
            # Digits right before a redirection are its fd (2>, 1>>), not a word.
            if in_word and c in "<>" and "".join(word).isdigit():
                word.clear()
                in_word = False
            end_word()
            op = next(o for o in OPERATORS if command.startswith(o, i))
            i += len(op)
            tokens.append(Op(op))
            if op in HEREDOCS:
                while i < n and command[i] in " \t":
                    i += 1
                delimiter, i = heredoc_delimiter(command, i)
                tokens.append(delimiter)
                pending_heredocs.append((delimiter, op == "<<-"))
        else:
            word.append(c)
            in_word = True
            i += 1
    end_word()
    if pending_heredocs:
        raise ValueError("unterminated heredoc")
    return tokens


def heredoc_delimiter(command: str, i: int) -> tuple:
    out = []
    n = len(command)
    while i < n and command[i] not in " \t\n<>&|;()":
        c = command[i]
        if c in "'\"":
            close = command.find(c, i + 1)
            if close < 0:
                raise ValueError("unterminated quote in heredoc delimiter")
            out.append(command[i + 1:close])
            i = close + 1
        elif c == "\\" and i + 1 < n:
            out.append(command[i + 1])
            i += 2
        else:
            out.append(c)
            i += 1
    if not out:
        raise ValueError("missing heredoc delimiter")
    return "".join(out), i


def segments(tokens: list):
    argv: list = []
    targets: list = []
    it = iter(tokens)
    for tok in it:
        if isinstance(tok, Op):
            if tok in SEPARATORS:
                yield argv, targets, tok
                argv, targets = [], []
                continue
            operand = next(it, None)
            if ">" in tok and operand is not None and not isinstance(operand, Op):
                targets.append(operand)
            continue
        argv.append(tok)
    yield argv, targets, None


def command_targets(words: list) -> list:
    if not words:
        return []
    name = os.path.basename(words[0])
    args = words[1:]
    operands = [a for a in args if not a.startswith("-")]
    if name == "tee":
        return operands
    if name == "sed":
        in_place = any(
            a == "--in-place" or a.startswith("--in-place=")
            or (a.startswith("-") and not a.startswith("--") and "i" in a[1:])
            for a in args
        )
        return operands if in_place else []
    if name in ("mv", "cp") and len(operands) >= 2:
        return [operands[-1]]
    return []


# Each target is paired with the directory it resolves against: the cwd as
# moved by the literal cds before it in the same command.
# A cd inside ( ... ) or $( ... ) runs in a subshell: the base saved at "("
# comes back at the matching ")".
def bash_targets(command: str, base, home) -> list:
    found = []
    saved = []
    for argv, redirects, separator in segments(tokenize(command)):
        words = argv
        while words and ASSIGNMENT_RE.match(words[0]):
            words = words[1:]
        found.extend((t, base) for t in redirects + command_targets(words))
        if words and words[0] == "cd":
            base = cd_base(words, base, home)
        if separator == "(":
            saved.append(base)
        elif separator == ")" and saved:
            base = saved.pop()
    return found


def deny(target: str) -> None:
    task_sh = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "scripts", "task.sh",
    )
    reason = (
        f"task-tracker: '{target}' is the tracker's index or counter and is "
        f"changed only through task.sh, which keeps IDs, columns, and UPDATED "
        f"consistent (a row added by hand leaves .counter behind, and the next "
        f"add reuses an existing ID). Use {task_sh} instead: add (new ticket), "
        f"update (fields, -a to append details), close, or delete. Details "
        f"(.tasks/details/<id>.md) may be edited directly. If .counter is "
        f"behind the rows, task.sh add prints the command a human runs in "
        f"their own terminal to fix it; ask them to run it."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def absolute_or_none(value):
    return value if isinstance(value, str) and os.path.isabs(value) else None


def protected_target(data):
    if not isinstance(data, dict) or not isinstance(data.get("tool_input"), dict):
        return None
    tool_input = data["tool_input"]
    base = absolute_or_none(data.get("cwd"))
    home = absolute_or_none(os.environ.get("HOME"))
    if data.get("tool_name") in ("Edit", "Write"):
        path = tool_input.get("file_path")
        targets = [(path, base)] if isinstance(path, str) and path else []
    elif data.get("tool_name") == "Bash":
        command = tool_input.get("command")
        targets = bash_targets(command, base, home) if isinstance(command, str) else []
    else:
        return None
    return next((t for t, b in targets if is_protected(t, b, home)), None)


def main() -> None:
    # Any internal failure lets the call through: see the output contract.
    try:
        target = protected_target(json.load(sys.stdin))
    except Exception:
        return
    if target:
        deny(target)


if __name__ == "__main__":
    main()
