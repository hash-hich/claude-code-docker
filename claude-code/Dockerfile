# claude-code: Claude Code with the tools it reaches for, the full image of
# this repository and the benchmark the lighter ones are measured against
# (README.md). It follows Anthropic's own devcontainer for Claude Code
# (.devcontainer/Dockerfile in github.com/anthropics/claude-code), keeping
# what serves the agent and leaving out what serves the developer at the
# keyboard: each block below says what it keeps from it, what it changes,
# and why. One directory per image, each Dockerfile self-contained with its
# own pins, so that a fork builds the one it wants with plain `docker build`
# and reads everything the image contains in one file:
#
#     scripts/build-image.sh claude-code
#
# tags the result with the Claude Code version pinned below. Nothing is
# copied from the build context: everything the image contains is either
# named below with a version and a checksum, or installed by apt.

# Pins. Everything downloaded during the build is named here with a version
# and a checksum, so that a clean checkout rebuilds the same content: the
# base image by the digest of its index, which covers both platforms, and
# the Claude Code binary by the checksums of its release manifest
# (https://downloads.claude.ai/claude-code-releases/<version>/manifest.json),
# one per platform because each platform is a different binary. A version
# bump changes the three values together. The devcontainer takes
# CLAUDE_CODE_VERSION as a build argument defaulting to "latest" and pins
# nothing else: what it builds depends on the day it is built, which suits a
# workstation and not an image a team shares.
ARG DEBIAN_DIGEST=sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132
ARG CLAUDE_CODE_VERSION=2.1.273
ARG CLAUDE_CODE_SHA256_AMD64=6c752e2cc7c110c9df15f26d8d134d438c5ae95dbd610efc1a308bf7f9c5f6c1
ARG CLAUDE_CODE_SHA256_ARM64=103cfab4d6ae898b6af692336fb662ffcc607075cc6408892bd350b3f549ebee

# Stage 1: download the native binary and check it against the pinned
# checksum. A separate stage keeps curl, its dependencies and the apt state
# of this step out of the final image. The devcontainer installs the npm
# package instead, `npm install -g @anthropic-ai/claude-code`, which is why
# it starts from node:20: the package only wraps the same native binary, so
# node is there for the installer, and for the JavaScript projects the
# devcontainer also hosts. The official install script is not used either:
# it fetches the latest release before installing the requested one, and
# leaves a launcher symlink plus a versions directory under $HOME.
FROM debian:trixie-slim@${DEBIAN_DIGEST} AS download
ARG CLAUDE_CODE_VERSION
ARG CLAUDE_CODE_SHA256_AMD64
ARG CLAUDE_CODE_SHA256_ARM64

# TARGETARCH is filled in by BuildKit with the platform being built, amd64 or
# arm64: the host's by default, or the one given to --platform. The release
# names amd64 "x64". Any other platform fails the build here, with the
# variable in the message, rather than at the checksum. The devcontainer
# reads the same information with `dpkg --print-architecture`, for the
# git-delta package it downloads, and checks no checksum.
ARG TARGETARCH

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
RUN case "${TARGETARCH}" in \
        amd64) platform=linux-x64 sha256="${CLAUDE_CODE_SHA256_AMD64}" ;; \
        arm64) platform=linux-arm64 sha256="${CLAUDE_CODE_SHA256_ARM64}" ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSL -o /claude \
        "https://downloads.claude.ai/claude-code-releases/${CLAUDE_CODE_VERSION}/${platform}/claude" \
    && echo "${sha256}  /claude" > /claude.sha256 \
    && sha256sum -c /claude.sha256 \
    && chmod 0755 /claude

# Stage 2: the image itself, on Debian slim rather than on node:20. The
# devcontainer's base is a full Debian with the Node toolchain and the
# buildpack-deps compilers, about 1 GB, because it also hosts the
# developer's JavaScript work; here Node is a layer a fork adds when its
# project needs it. Debian slim rather than Alpine: the release ships a musl
# build too, and Alpine would save a few tens of MB on an image whose binary
# weighs 230 MB, at the cost of the glibc ecosystem a fork adds its tools
# from (prebuilt binaries, Python wheels, apt itself). Trixie rather than
# the devcontainer's bookworm: the current stable, with the current git.
FROM debian:trixie-slim@${DEBIAN_DIGEST}
ARG CLAUDE_CODE_VERSION

# The tools the agent reaches for: the devcontainer's apt list, minus what
# it installs for the developer at the keyboard or for its firewall, plus
# what its node:20 base carries without naming it. Kept from its list: git,
# gh, jq, less, procps, unzip, dnsutils and gnupg (gnupg2 there, a
# transitional name for the same package). Left out: zsh, fzf, nano, vim,
# man-db and git-delta, the developer's shell and editors; iptables, ipset,
# iproute2 and aggregate, used by its init-firewall.sh, which needs
# NET_ADMIN and has no place in an image run with plain `docker run`; sudo,
# which it grants for that firewall script only. Named here because node:20
# has them from buildpack-deps: ca-certificates, curl, openssh-client and
# make. Added, with no counterpart there: lsof and psmisc, for the ports and
# processes the agent checks and kills; rsync, for copying trees; ripgrep,
# which the binary bundles for its own search tool but does not put on PATH
# for the commands the agent runs in bash; tini, for the entrypoint below.
# Runtimes and project tooling (Node, Go, Python, linters) are the layers a
# fork adds on top. Package versions are not pinned: Debian keeps only the
# current build of a package on its mirrors, so a pin would break at the
# next security update instead of reproducing anything. The apt lists are
# removed so that no package index is left in the image, as the
# devcontainer does.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        gh \
        git \
        gnupg \
        jq \
        less \
        lsof \
        make \
        openssh-client \
        procps \
        psmisc \
        ripgrep \
        rsync \
        tini \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# The binary, on PATH for every user and owned by root: the agent runs it
# and cannot replace it. The devcontainer's launcher sits in an npm prefix
# it hands over to its user, so that npm can update it in place.
COPY --from=download /claude /usr/local/bin/claude

# A dedicated user, uid 1000, as the devcontainer's `node` user, which it
# inherits from its base image; here it is created, and named for what it
# is. The boundary is the container, whose kernel is the host's: root inside
# is root on every bind mount, and an escape lands as root. Claude Code
# itself refuses --dangerously-skip-permissions as root. uid 1000 is the
# first user of most Linux distributions, so what the agent writes to a bind
# mount belongs to the person who mounted it; Docker Desktop remaps the uid
# anyway. No sudo: the devcontainer grants it for its firewall script only,
# and a fork adds what the agent lacks as a layer. The user owns its home,
# where Claude Code keeps its state and credentials (~/.claude,
# ~/.claude.json); the devcontainer pre-creates ~/.claude and mounts a named
# volume on it to carry the login across rebuilds, which `docker run -v`
# does the same way. /workspace is created here so that it exists, owned by
# the agent, when nothing is mounted on it, as the devcontainer creates it
# for its workspaceMount. USER names the uid, not the name, so that a
# runtime which requires a non-root user (Kubernetes runAsNonRoot) can check
# it without reading /etc/passwd.
RUN useradd --create-home --uid 1000 --user-group --shell /bin/bash agent \
    && mkdir /workspace \
    && chown agent:agent /workspace
USER 1000
WORKDIR /workspace

# DISABLE_UPDATES blocks background and manual updates, so that the version
# pinned above is the one that runs; the Claude Code documentation names it
# for distributing Claude Code through your own channel, which an image is.
# Updating is bumping the pin and rebuilding. The devcontainer sets no such
# variable: built on "latest", it has no version to hold. Its other
# variables serve the developer's shell (SHELL, EDITOR, VISUAL, TZ), its npm
# prefix, or orientation (DEVCONTAINER=true), and have no object here.
ENV DISABLE_UPDATES=1

# OCI labels, so that `docker inspect` says what the image is and which
# Claude Code it holds. The devcontainer has none: its identity is the
# devcontainer.json next to it.
LABEL org.opencontainers.image.title="claude-code" \
      org.opencontainers.image.description="Claude Code with the tools it reaches for" \
      org.opencontainers.image.version="${CLAUDE_CODE_VERSION}"

# The entrypoint is the agent behind tini: claude is PID 1 otherwise, and
# the shells it spawns would leave zombies it does not reap and signals it
# does not forward. `docker run` of this image is a claude command, and its
# arguments are claude's (`--version`, `-p "..."`). Without arguments claude
# opens its interactive session, which is why there is no CMD. A shell in
# the image is `docker run --entrypoint bash`. The devcontainer has no
# entrypoint: the editor keeps its container alive and the developer runs
# claude from a terminal, so PID 1 is never claude there.
ENTRYPOINT ["tini", "--", "claude"]
