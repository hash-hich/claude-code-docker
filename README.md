# claude-code-docker-lite

**Claude Code in a container, with nothing you did not ask for.**

A lightweight image of Claude Code, built to be forked. Take the project, keep
the pieces you want, drop the rest, and build an image that is yours.

## Why a container

A container draws the line.

**A context you control.** Every message to Claude carries what was loaded
at startup: the system prompt, the tool definitions, the skills, the memory
files. On a workstation that set grows with time: an MCP server added for
one project and never removed, skills and plugins that announce themselves
on every request, notes left by other work. All of it costs tokens on every
turn and dilutes the attention the model gives to your prompt. In a
container the agent loads what the image declares, and nothing that drifted
in. [How much context an image sends](#how-much-context-an-image-sends)
shows how to measure it.

**A boundary you choose.** The agent sees the directories you mount and
nothing else. It cannot read a credential you did not hand it, and what it
breaks, it breaks inside the container. This is what makes it reasonable to
let it run without a permission prompt at every step, which is the mode
Anthropic's own devcontainer exists for.

**The same thing everywhere.** The image pins the Claude Code version and
every tool next to it. A teammate, a CI runner and a server all run the same
agent with the same tools, and a bug reproduces on the first try instead of
depending on what each machine happens to have installed.

**Disposable.** A container is started for a task and thrown away after. No
state accumulates on your machine, no half-installed package survives, and
the next run starts from the image you declared.

## Why this project

Running Claude Code in a container usually means inheriting a big image: a
full Node toolchain, a pile of packages, and a set of skills and settings
someone else picked. Most of it is never used, all of it ships anyway, and
none of it is easy to change.

This project takes the opposite path.

**Light by default.** The image carries Claude Code and what it needs to run.
Nothing else gets in unless you put it there.

**Yours to shape.** The project is a starting point, not a finished product.
Fork it, enable the skills you rely on, disable the ones you never use, add
the tools your work needs, and build. The result is an image that matches how
you work, not how someone else does.

**Nothing hidden.** Everything that ends up in the image is declared in the
repository. What you read is what you get, and a fresh clone rebuilds the same
thing.

**Grounded in the reference.** The image follows Anthropic's own
[devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
for Claude Code: the same dedicated user, the tools the agent reaches for,
without the pieces that serve the developer at the keyboard. Each block of
the Dockerfile says what it keeps from it, what it changes, and why.

## Who it is for

- You run Claude Code in containers and want a smaller, faster image.
- You want a Claude Code setup you control end to end: agent version, tools,
  skills.
- You need one image for a team, and want every member to run the same thing.

## How much context an image sends

Every message to Claude carries the system prompt, the tool definitions,
the skills and the memory files loaded at startup. That is the cost of an
image before the first word of your prompt, and it is what a fork changes
when it adds or removes something. To see it:

```
scripts/build-image.sh claude-code
scripts/benchmark-image.sh claude-code:2.1.273
```

The script runs claude's own `/context` command in the image, without
network and without a project, prints its breakdown, then what that
context costs in prompt cache at the model's price. The numbers are
claude's estimates, not a count by the API.

**The benchmark consumes no tokens.** Nothing is sent to Anthropic: the
container runs with no network, no API key is needed, and `/context`
computes its estimate locally. Run it as often as you like, it costs
nothing.

The estimate depends on the model: the system prompt and the tool
descriptions differ from one model to the next, and so does the tokenizer.
Without `--model`, claude estimates for its default model and names it at
the top of its output. Pass `--model` to estimate for the one you run, and
compare two images with the same model:

```
scripts/benchmark-image.sh --model claude-fable-5-1 claude-code:2.1.273
```

`claude-code`, the full image, is the benchmark. With Claude Code 2.1.273,
estimated for claude-opus-5, its default:

| Category               | Tokens |
|------------------------|--------|
| System prompt          | 3k     |
| System tools           | 11.6k  |
| System tools (deferred)| 15.6k  |
| Skills (built-in)      | 1.8k   |
| Total before the prompt| 16.4k  |

Deferred tools are listed by name only and loaded on demand, which is why
the total is below the sum. The same image estimated for claude-fable-5-1
loads 17.5k, and for claude-sonnet-5 30.7k. Benchmark your fork the same
way and compare.

The cost table below the breakdown applies the prices Anthropic publishes,
pinned in the script with their date, to the total: Claude Code writes the
context to the prompt cache at the first message of a session and reads it
at every following turn, so the write is paid once per session and the read
once per turn. For claude-fable-5-1, the 17.5k tokens are 0.22 USD to write
for five minutes, 0.35 USD for an hour, and 0.004 USD to read.

## Status

Early stage. The project is being set up and nothing is buildable yet. This
README states the goal; the rest follows.

## License

To be decided.
