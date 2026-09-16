# What `/context` leaves out

`/context` does not account for the instructions an MCP server provides.
They reach the model on every turn, and no line of the breakdown carries
them, not even the total.

`ctx-base` and `ctx-mcp` are the pair that shows it. They are `custom/`
copied twice, and the only difference between them is that `ctx-mcp`
declares one MCP server in `config/mcp.json`: `mcp-noise/`, a stdio server
built on the official Python SDK, holding a single tool with the shortest
body a tool can have, and an `instructions` field of 1953 characters, 345
words. One trivial tool, so that whatever the benchmark fails to account
for can only be the instructions.

## What the benchmark prints

```
scripts/build-image.sh claude-code     # the base, once
scripts/build-image.sh ctx-base
scripts/build-image.sh ctx-mcp
scripts/benchmark-image.sh --model claude-opus-5 ctx-base:2.1.273 | tee context-base.txt
scripts/benchmark-image.sh --model claude-opus-5 ctx-mcp:2.1.273  | tee context-mcp.txt
diff context-base.txt context-mcp.txt
```

The diff is twelve lines. A `MCP Tools` section appears, crediting the one
tool with 66 tokens, and the server's instructions appear nowhere. Both
images print the same total, **16.7k**, unchanged to the tenth of a
thousand. The two `(deferred)` lines are outside that total: the categories
it sums are 3.1 + 11.6 + 0.041 + 0.133 + 1.9, which is the 16.7k printed,
in both images alike.

## What the model actually receives

Measured on the host binary, same version as the image, `2.1.273`, talking
over stdio to the server of `ctx-mcp:2.1.273` itself, from a neutral working
directory so that no memory file or git status enters the prompt. The
figures are the API's own count, `input + cache_creation + cache_read`
reported by `--output-format json`, not an estimate:

| Run                          | Prompt tokens | Against no server |
|------------------------------|---------------|-------------------|
| no server at all             |        26 686 |                   |
| server, instructions emptied |        26 732 |              + 46 |
| server, instructions in full |        27 385 |             + 699 |

The tool and its wiring cost 46 tokens. The instructions cost **653 tokens**,
on every turn, and `/context` reports none of them.

## That the instructions are loaded, not dropped

A count that moves proves something arrives, not what. The last line of
`mcp-noise/instructions.txt` asks for the word ORANGE as a safe word, and it
is the last line on purpose: a truncated field loses it first.

```
$ claude -p "What is the safe word?" --strict-mcp-config --mcp-config <the noise server>
ORANGE

$ claude -p "What is the safe word?" --strict-mcp-config --mcp-config '{"mcpServers":{}}'
No safe word was in my context. [...] the instructions of the noise MCP
server were not present in my context when you asked.
```

The whole field reaches the model, and the same field is invisible to
`/context`.

## Why 1953 characters and not more

Claude Code truncates this field at 2048 characters per server, before the
system prompt is built, with a message reading `Server instructions
truncated from N to 2048 chars`. A larger fixture would measure the cap
rather than the omission, so `instructions.txt` sits 95 characters under it
and arrives whole. The cap bounds what one server can hide, not what a
session can: the omission is per server, and every connected server adds its
own share to a total that never moves.
