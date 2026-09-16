# ctx-mcp: the measured half of a pair of images built to show what the
# `/context` command leaves out. It is ctx-base plus one MCP server, which
# declares a large `instructions` field and a single trivial tool:
#
#     scripts/build-image.sh claude-code     # the base, once
#     scripts/build-image.sh ctx-mcp
#     scripts/benchmark-image.sh --model claude-opus-5 ctx-mcp:2.1.273
#
# Diffed against ctx-base, the benchmark shows the MCP tool appearing in the
# breakdown and the total standing still, while the instructions reach the
# model. README.md next to this file holds the numbers and the method.
#
# The two Dockerfiles differ only by the block that installs the server
# below. Packages cost megabytes and start-up time, never context: Claude
# Code describes its own tools, not what it finds on the PATH (README.md),
# so this layer changes nothing the benchmark measures except through the
# server it makes runnable.

# The base image and the tag of this one. Both carry the Claude Code version,
# so that custom:2.1.273 is built on claude-code:2.1.273 and no pair of
# images can drift apart. Build the base first: this FROM reads it from the
# local image store, or from your registry once you publish it there.
ARG CLAUDE_CODE_VERSION=2.1.273
FROM claude-code:${CLAUDE_CODE_VERSION}

USER 0
# Python and the official MCP SDK, for the stdio server copied below. The
# version is pinned like every other download in this repository, so that a
# rebuild carries the same server. A virtual environment rather than
# --break-system-packages: Debian marks its Python as externally managed,
# and the environment keeps the SDK and its dependencies out of the system
# site-packages the agent may itself install into.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/mcp-noise/venv \
    && /opt/mcp-noise/venv/bin/pip install --no-cache-dir mcp==2.2.0

# The server, root-owned like the entrypoint and the binary: the agent runs
# it and cannot rewrite the instructions it is measured against.
COPY mcp-noise/server.py mcp-noise/instructions.txt /opt/mcp-noise/

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
