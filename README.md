# claude-code-docker-lite

**Claude Code in a container, with nothing you did not ask for.**

A lightweight image of Claude Code, built to be forked. Take the project, keep
the pieces you want, drop the rest, and build an image that is yours.

## Why

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
network and without a project, and prints its breakdown. The numbers are
claude's estimates, not a count by the API. Nothing is sent to Anthropic.

`claude-code`, the full image, is the benchmark. With Claude Code 2.1.273:

| Category               | Tokens |
|------------------------|--------|
| System prompt          | 3k     |
| System tools           | 11.6k  |
| System tools (deferred)| 15.6k  |
| Skills (built-in)      | 1.8k   |
| Total before the prompt| 16.4k  |

Deferred tools are listed by name only and loaded on demand, which is why
the total is below the sum. Benchmark your fork the same way and compare.

## Status

Early stage. The project is being set up and nothing is buildable yet. This
README states the goal; the rest follows.

## License

To be decided.
