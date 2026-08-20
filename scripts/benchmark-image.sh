#!/bin/sh
# Benchmarks an image: prints the context Claude Code loads in it before the
# first message, as claude's own /context command breaks it down (system
# prompt, tools, skills, memory files). The numbers are claude's estimates,
# not the API's count, and nothing is sent: the container has no network,
# and /context does not need one. The image is run bare, without a mounted
# project, so that the figure is the image's alone; the default image is
# the benchmark every fork compares itself to (README.md).
#
# Usage: scripts/benchmark-image.sh <image>
set -eu

if [ $# -ne 1 ]; then
    echo "usage: $0 <image>" >&2
    exit 2
fi

exec docker run --rm --network none "$1" -p /context
