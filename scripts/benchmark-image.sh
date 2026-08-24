#!/bin/sh
# Benchmarks an image: prints the context Claude Code loads in it before the
# first message, as claude's own /context command breaks it down (system
# prompt, tools, skills, memory files). The numbers are claude's estimates,
# not the API's count, and nothing is sent: the container has no network,
# and /context does not need one. The image is run bare, without a mounted
# project, so that the figure is the image's alone; the default image is
# the benchmark every fork compares itself to (README.md).
#
# The estimate depends on the model: the system prompt and the tool
# descriptions differ from one model to the next, and so does the
# tokenizer. Without --model, claude estimates for its default model and
# names it at the top of its output; compare two images with the same model.
#
# Usage: scripts/benchmark-image.sh [--model <model>] <image>
set -eu

usage() {
    echo "usage: $0 [--model <model>] <image>" >&2
    exit 2
}

model=""
while [ $# -gt 0 ]; do
    case "$1" in
        --model)
            [ $# -ge 2 ] || usage
            model="$2"
            shift 2
            ;;
        --model=*)
            model="${1#--model=}"
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage
            ;;
        *)
            break
            ;;
    esac
done
[ $# -eq 1 ] || usage
image="$1"

if [ -n "$model" ]; then
    set -- --model "$model"
else
    set --
fi
exec docker run --rm --network none "$image" "$@" -p /context
