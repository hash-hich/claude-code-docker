# custom: your own image, built on claude-code. Copy this directory under a
# name of your own, put your files in config/, add the packages you need
# below, and build:
#
#     scripts/build-image.sh claude-code     # the base, once
#     scripts/build-image.sh custom
#     scripts/benchmark-image.sh custom:2.1.273
#
# The benchmark prints what your additions cost against the base image
# (README.md). Everything under config/ is an example meant to be replaced
# or deleted: nothing here is required, and removing a file removes what it
# added, with no change to this Dockerfile.

# The base image and the tag of this one. Both carry the Claude Code version,
# so that custom:2.1.273 is built on claude-code:2.1.273 and no pair of
# images can drift apart. Build the base first: this FROM reads it from the
# local image store, or from your registry once you publish it there.
ARG CLAUDE_CODE_VERSION=2.1.273
FROM claude-code:${CLAUDE_CODE_VERSION}

# Packages your agent needs and the base image does not carry: language
# runtimes, linters, database clients, cloud CLIs. The base holds the tools
# Claude Code reaches for in any project, this layer holds the ones yours
# needs. Adding packages costs megabytes and start-up time, never context:
# Claude Code describes its own tools, not what it finds on the PATH
# (README.md). Uncomment and edit.
USER 0
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         nodejs \
#         npm \
#         sqlite3 \
#     && rm -rf /var/lib/apt/lists/*

# The entrypoint wrapper, root-owned like the binary it calls, so that the
# agent cannot rewrite what starts it. It exists for one reason: a system
# prompt addition is only accepted on the command line, there is no settings
# key and no environment variable for it, so something has to add the flag.
COPY entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod 0755 /usr/local/bin/claude-entrypoint.sh
USER 1000

# Everything the agent reads at startup, staged in one directory and then
# put where Claude Code looks for it. One COPY rather than one per file, so
# that adding or deleting a file in config/ needs no edit here:
#
#     config/CLAUDE.md          -> ~/.claude/CLAUDE.md, memory loaded every session
#     config/settings.json      -> ~/.claude/settings.json, the settings file
#     config/mcp.json           -> ~/.claude.json, user scope MCP servers
#     config/skills/<name>/     -> ~/.claude/skills/<name>/, one directory per skill
#     config/agents/<name>.md   -> ~/.claude/agents/<name>.md, one file per agent
#     config/system-prompt.md   -> read by the entrypoint, appended to the prompt
#
# User scope is what a container wants: skills, agents and MCP servers
# declared there load without the approval a project scope .mcp.json asks
# for, and they follow the agent whatever directory it is pointed at.
COPY --chown=agent:agent config/ /home/agent/staging/
RUN set -eu; \
    mkdir -p /home/agent/.claude; \
    for f in CLAUDE.md settings.json system-prompt.md; do \
        if [ -f "/home/agent/staging/$f" ]; then \
            cp "/home/agent/staging/$f" "/home/agent/.claude/$f"; \
        fi; \
    done; \
    for d in skills agents; do \
        if [ -d "/home/agent/staging/$d" ]; then \
            cp -R "/home/agent/staging/$d" "/home/agent/.claude/$d"; \
        fi; \
    done; \
    if [ -f /home/agent/staging/mcp.json ]; then \
        cp /home/agent/staging/mcp.json /home/agent/.claude.json; \
    fi; \
    rm -rf /home/agent/staging

# The wrapper replaces claude as the command behind tini, and passes on
# whatever arguments docker run gives, so this image is used exactly like
# the base one.
ENTRYPOINT ["tini", "--", "/usr/local/bin/claude-entrypoint.sh"]
