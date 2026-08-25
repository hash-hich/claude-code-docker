#!/bin/sh
# Benchmarks an image: prints the context Claude Code loads in it before the
# first message, as claude's own /context command breaks it down (system
# prompt, tools, skills, memory files), then what that context costs in
# prompt cache at the model's price. The numbers are claude's estimates,
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

# Prices in USD per million input tokens, from
# https://platform.claude.com/docs/en/about-claude/pricing as of 2026-09-16.
# Cache prices derive from the base input price: a 5-minute write costs
# 1.25x, a 1-hour write 2x, a read 0.1x, except on Fable 5.1 and Mythos 5.1
# where a read costs 0.025x. Claude Code writes its context to the cache at
# the first message of a session and reads it at every following turn, so
# the write is paid once per session and the read once per turn.
PRICING_DATE=2026-09-16
PRICING_URL=https://platform.claude.com/docs/en/about-claude/pricing

# Prints "<base price> <read multiplier>" for a model id, or nothing when
# the model is not in the table. Ids carry suffixes ("[1m]", a date) and
# aliases resolve to ids before /context prints them, so the match is on
# the family and generation.
price() {
    case "$1" in
        *fable-5-1*|*mythos-5-1*) echo "10 0.025" ;;
        *fable-5*|*mythos-5*) echo "10 0.1" ;;
        *opus-5*|*opus-4-[5678]*) echo "5 0.1" ;;
        *opus-4*) echo "15 0.1" ;;
        *sonnet-5*) echo "2 0.1" ;;
        *sonnet-4*) echo "3 0.1" ;;
        *haiku-4-5*) echo "1 0.1" ;;
        *haiku-3-5*) echo "0.8 0.1" ;;
        *) ;;
    esac
}

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
context=$(docker run --rm --network none "$image" "$@" -p /context)
printf '%s\n' "$context"

# /context prints "**Model:** <id>" and "**Tokens:** <used> / <window>",
# with the count rounded to a tenth of a thousand, as in "16.4k".
used_model=$(printf '%s\n' "$context" | sed -n 's/^\*\*Model:\*\* *\([^ ]*\).*/\1/p' | head -n 1)
tokens=$(printf '%s\n' "$context" | sed -n 's/^\*\*Tokens:\*\* *\([0-9.]*k\{0,1\}\) .*/\1/p' | head -n 1)
if [ -z "$used_model" ] || [ -z "$tokens" ]; then
    echo "$0: no model or token count in the output of /context" >&2
    exit 1
fi
prices=$(price "$used_model")
if [ -z "$prices" ]; then
    echo "$0: no price known for $used_model, see $PRICING_URL" >&2
    exit 1
fi

printf '\n### Estimated cost in prompt cache\n\n'
printf 'Prices of %s for %s, %s\n\n' "$PRICING_DATE" "$used_model" "$PRICING_URL"
# shellcheck disable=SC2086 # prices holds two words on purpose
printf '%s %s %s\n' "$tokens" $prices | awk '{
    tokens = $1
    if (tokens ~ /k$/) { sub(/k$/, "", tokens); tokens *= 1000 }
    base = $2; read = $3
    printf "| Operation           | USD per MTok | For this context |\n"
    printf "|---------------------|--------------|------------------|\n"
    printf "| Cache write, 5 min  | %12.2f | %16.4f |\n", base * 1.25, tokens * base * 1.25 / 1e6
    printf "| Cache write, 1 hour | %12.2f | %16.4f |\n", base * 2, tokens * base * 2 / 1e6
    printf "| Cache read          | %12.3f | %16.4f |\n", base * read, tokens * base * read / 1e6
}'
