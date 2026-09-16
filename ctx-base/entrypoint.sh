#!/bin/sh
# Starts claude, adding the system prompt kept in the image when there is
# one. A system prompt addition has no settings key and no environment
# variable, only --append-system-prompt-file, so it cannot be baked into a
# file the way skills, agents, memory, settings and MCP servers are. The
# flag goes before the caller's arguments, which therefore keep the last
# word, and the file is optional: delete config/system-prompt.md and this
# image starts plain claude.
set -eu

prompt=/home/agent/.claude/system-prompt.md
if [ -f "$prompt" ]; then
    set -- --append-system-prompt-file "$prompt" "$@"
fi

exec claude "$@"
