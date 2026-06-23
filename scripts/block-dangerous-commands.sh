#!/usr/bin/env bash
# block-dangerous-commands.sh
#
# Claude Code PreToolUse hook for the Bash tool.
# Reads the tool call JSON on stdin, inspects the command, and asks for
# explicit confirmation before destructive / exfiltration-prone commands.
#
# Design goals: CAREFUL, NOT ANNOYING.
#   - It returns "ask" (a confirmation prompt), never a hard "deny", so you
#     are always one keystroke from proceeding when you mean it.
#   - Common safe cleanups (rm -rf node_modules, dist, build, ...) are
#     whitelisted and pass through silently.
#   - On any parse failure it FAILS OPEN (exit 0) so it can never wedge you.
#
# Output contract (Claude Code hooks):
#   exit 0 + JSON on stdout with permissionDecision "ask" -> prompt the user.
#   exit 0 + no output                                     -> proceed normally.

set -uo pipefail

input="$(cat)"

# --- Extract the command string (jq -> python3 -> crude grep fallback) ---
cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | python3 -c 'import sys,json;
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    pass' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')"
fi

# Nothing to inspect -> allow.
[ -z "$cmd" ] && exit 0

ask() {
  # $1 = human-readable reason
  reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg r "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $r
      }
    }'
  else
    # Minimal hand-rolled JSON (reason kept simple, no escaping needed).
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}' "$reason"
  fi
  exit 0
}

# --- Whitelist: well-known safe cleanups pass through silently ---
# Match `rm -rf <dir>` (any flag order) where <dir> is a known throwaway.
safe_rm='(node_modules|dist|build|\.next|\.nuxt|\.turbo|\.cache|coverage|__pycache__|\.pytest_cache|target|out|\.parcel-cache|\.svelte-kit)'
if printf '%s' "$cmd" | grep -Eq "^[[:space:]]*rm[[:space:]]+-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+([^[:space:]]*/)?${safe_rm}/?[[:space:]]*$"; then
  exit 0
fi

# --- Dangerous patterns -> ask for confirmation ---

# Catastrophic filesystem deletes.
printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*(-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+)?(/|/\*|~|\$HOME|\*)([[:space:]]|$)' \
  && ask "Destructive 'rm' against a broad/root path. Confirm you mean this exact target."
printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*[rf]' \
  && ask "Recursive/forced 'rm'. Confirm the target is correct and not needed."

# Git history / work destruction.
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]]+.*(--force([^-]|$)|-f([[:space:]]|$))' \
  && ask "git force-push can overwrite remote history. Confirm branch and intent."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' \
  && ask "git reset --hard discards uncommitted work. Confirm."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*[df]' \
  && ask "git clean deletes untracked files. Confirm."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(\.|--[[:space:]]+\.|\.\/)' \
  && ask "git checkout/restore of '.' discards local changes. Confirm."
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D' \
  && ask "git branch -D force-deletes a branch. Confirm it is merged/expendable."

# Destructive SQL.
printf '%s' "$cmd" | grep -Eiq '(DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]+TABLE|DELETE[[:space:]]+FROM[[:space:]]+[^[:space:]]+[[:space:]]*;?$)' \
  && ask "Destructive SQL (DROP/TRUNCATE/unfiltered DELETE). Confirm target and environment."

# Infra / container destruction.
printf '%s' "$cmd" | grep -Eq 'kubectl[[:space:]]+delete' \
  && ask "kubectl delete removes live resources. Confirm context/namespace."
printf '%s' "$cmd" | grep -Eq 'docker[[:space:]]+system[[:space:]]+prune' \
  && ask "docker system prune removes containers/images/volumes. Confirm."
printf '%s' "$cmd" | grep -Eq 'docker[[:space:]]+(rm|rmi)[[:space:]]+-[a-zA-Z]*f' \
  && ask "Forced docker remove. Confirm."

# Pipe-to-shell of remote scripts.
printf '%s' "$cmd" | grep -Eq '(curl|wget)[[:space:]]+.*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh)' \
  && ask "Piping a downloaded script straight into a shell. Inspect the script first."

# Secret / token exfiltration smell: reading env or key material and sending it out.
printf '%s' "$cmd" | grep -Eq '(printenv|env|cat[[:space:]]+.*\.env|echo[[:space:]]+\$[A-Z_]*(TOKEN|SECRET|KEY|PASSWORD))' \
  && printf '%s' "$cmd" | grep -Eq '(curl|wget|nc|ncat|http)' \
  && ask "Command reads secrets/env and pipes to the network. Possible exfiltration. Confirm."

# Staging/committing/pushing generated plan & spec working docs.
# These are local thinking artifacts (docs/superpowers/plans|specs, *-design.md)
# and are globally gitignored; this catches the case where the agent reaches for
# `git add -f` or names the path explicitly. Returns "ask", never blocks.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(add|commit|push)([[:space:]]|$)'; then
  printf '%s' "$cmd" | grep -Eq '(docs/superpowers/(plans|specs)|[^[:space:]]*-design\.md|[^[:space:]]*\.(plan|spec)\.md)' \
    && ask "About to git add/commit/push a plan or spec doc. These are local working artifacts (kept out of git on purpose). Confirm you really want it tracked."
  printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+add[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-f' \
    && ask "git add -f force-stages ignored files (plan/spec docs are ignored by design). Confirm."
fi

# Default: allow.
exit 0
