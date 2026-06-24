#!/usr/bin/env bash
# notify.sh
#
# Claude Code Notification hook. Fires when Claude needs attention
# (e.g. waiting on input or a permission decision). Degrades gracefully
# on every platform; never fails the session.
#
# Reads the notification JSON on stdin; surfaces the message via the best
# available channel and always exits 0.
set -uo pipefail

input="$(cat)"
msg=""
if command -v jq >/dev/null 2>&1; then
  msg="$(printf '%s' "$input" | jq -r '.message // empty' 2>/dev/null)"
fi
[ -z "$msg" ] && msg="Claude Code needs your attention."

if [ "$(uname)" = "Darwin" ] && command -v osascript >/dev/null 2>&1; then
  # Pass the message as an argv item so no shell/AppleScript metacharacters are interpreted.
  osascript - "$msg" >/dev/null 2>&1 <<'APPLESCRIPT' || true
on run argv
    display notification (item 1 of argv) with title "Claude Code"
end run
APPLESCRIPT
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "$msg" >/dev/null 2>&1 || true
else
  # Terminal bell + stderr fallback.
  printf '\a[Claude Code] %s\n' "$msg" 1>&2 || true
fi
exit 0
