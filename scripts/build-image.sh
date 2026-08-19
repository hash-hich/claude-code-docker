#!/bin/sh
# Builds one image of this repository and tags it with the Claude Code
# version its Dockerfile pins, so that the tag is never typed by hand and
# always matches the binary inside: claude-code:2.1.273 holds 2.1.273. The
# build is for the host platform; the Dockerfiles also build for the other
# one with `docker build --platform`.
#
# Usage: scripts/build-image.sh <name>   (a directory holding a Dockerfile)
set -eu

if [ $# -ne 1 ]; then
    echo "usage: $0 <name>" >&2
    exit 2
fi
name="$1"
dockerfile="$name/Dockerfile"
if [ ! -f "$dockerfile" ]; then
    echo "$0: no $dockerfile" >&2
    exit 2
fi

version=$(sed -n 's/^ARG CLAUDE_CODE_VERSION=\(.*\)$/\1/p' "$dockerfile")
if [ -z "$version" ]; then
    echo "$0: no ARG CLAUDE_CODE_VERSION in $dockerfile" >&2
    exit 1
fi

exec docker build -t "$name:$version" "$name"
