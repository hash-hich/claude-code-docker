#!/bin/sh
# Prints the Claude Code version a Dockerfile pins, so that the tag of an
# image is never typed by hand and always matches the binary inside:
# claude-code:2.1.273 holds 2.1.273. Read by scripts/build-image.sh for the
# local build and by the publish workflow for the tag it pushes to the
# registry, so that the two can never name the same image differently.
#
# Usage: scripts/image-version.sh <name>   (a directory holding a Dockerfile)
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

echo "$version"
