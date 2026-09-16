# claude-code-docker

**Claude Code in a container, with a context you can measure.**

This project holds a Docker image carrying what Claude Code needs to work.
It starts the agent on a fresh, known context, which is the main lever there
is on what a session costs. Fork the repository to add the tools, the skills
and whatever else your own image calls for. A benchmark script comes with
it, so that you can measure what you built and compare it to the image you
started from.

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

## Where the image comes from

The image follows Anthropic's own
[devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer)
for Claude Code, keeping its dedicated user and the tools the agent reaches
for. What it drops is what that devcontainer installs for the person using
it, the editors, the interactive shell and the manual pages, along with the
packages its network firewall needs and the sudo rights that go with them.
Each block of the Dockerfile says what it keeps, what it changes, and why.

## Pulling the image

Every push to `main` that changes the image publishes it to the GitHub
Container Registry, so that running it takes no build:

```
docker run --rm ghcr.io/hash-hich/claude-code:2.1.273 --version
```

Pull the version tag rather than `latest`. It names the Claude Code version
the image holds, which is the promise the whole repository is built on;
`latest` only follows `main` and says nothing about what is inside.

That tag is read from the Dockerfile by the same script the local build
uses, so an image pulled from the registry and one built with
`scripts/build-image.sh` carry the same binary. A fork publishes under its
own account with nothing to configure: the workflow takes the owner from the
repository it runs in, and its credentials are the token GitHub already
gives the job. Only `claude-code` is published, `custom/` being an example
to copy rather than an image to pull.

## Who it is for

- You want to work with Claude without pollution from previous tasks.
- You add skills, MCP servers or memory files, and want to know what each
  one costs on every turn.
- You need one image for a team, and want every member to run the same
  thing.

## Building your own image

`custom/` is a working image built on `claude-code`, and the place to put
what your agent needs. Copy the directory under a name of your own, edit
what is in it, build:

```
scripts/build-image.sh claude-code
scripts/build-image.sh custom
scripts/benchmark-image.sh custom:2.1.273
```

Everything the agent reads at startup is a file under `custom/config/`, and
the Dockerfile copies each one where Claude Code looks for it. Add a file to
add the thing, delete it to remove it, the Dockerfile stays untouched.

| What you add       | Where it goes               | Loaded as                |
|--------------------|-----------------------------|--------------------------|
| Memory             | `config/CLAUDE.md`          | instructions, every turn |
| System prompt      | `config/system-prompt.md`   | appended to the prompt   |
| Skills             | `config/skills/<name>/`     | one directory per skill  |
| Subagents          | `config/agents/<name>.md`   | one file per agent       |
| MCP servers        | `config/mcp.json`           | user scope, no approval  |
| Settings           | `config/settings.json`      | the settings file        |
| Command line tools | a package in the Dockerfile | installed by apt         |

Those all land in the agent's home, which is user scope. It is what a
container wants: skills, subagents and MCP servers declared there load
without the approval a project `.mcp.json` asks for, and they follow the
agent into whatever directory you point it at.

The system prompt is the exception to the file rule. Claude Code accepts an
addition to it only on the command line, with no settings key and no
environment variable, so the image ships a small entrypoint that adds the
flag when the file is there. That is the whole reason `custom/` has an
entrypoint of its own.

The example configuration is deliberately tiny, and the benchmark shows what
it costs: 16.4k for the base image, 16.7k with it, itemised down to the
single skill and the single subagent.

| Addition in `custom/`     | Tokens |
|---------------------------|--------|
| Memory file               | 133    |
| System prompt             | ~100   |
| One skill                 | ~60    |
| One subagent              | 41     |

## How much context an image sends

Every message to Claude carries the system prompt, the tool definitions,
the skills and the memory files loaded at startup. That is what the agent
costs before your first word, and what grows every time you add something.
To see it:

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
compare two setups with the same model:

```
scripts/benchmark-image.sh --model claude-fable-5-1 claude-code:2.1.273
```

The image is the floor every addition is measured from. With Claude Code
2.1.273, estimated for claude-opus-5, its default:

| Category               | Tokens |
|------------------------|--------|
| System prompt          | 3k     |
| System tools           | 11.6k  |
| System tools (deferred)| 15.6k  |
| Skills (built-in)      | 1.8k   |
| Total before the prompt| 16.4k  |

Deferred tools are listed by name only and loaded on demand, which is why
the total is below the sum. The same image estimated for claude-fable-5-1
loads 17.5k, and for claude-sonnet-5 30.7k.

The cost table below the breakdown applies the prices Anthropic publishes,
pinned in the script with their date, to the total: Claude Code writes the
context to the prompt cache at the first message of a session and reads it
at every following turn, so the write is paid once per session and the read
once per turn. For claude-fable-5-1, the 17.5k tokens are 0.22 USD to write
for five minutes, 0.35 USD for an hour, and 0.004 USD to read.

## What the measurements show

Four results, each reproducible with the commands above.

**What the image contains does not change the number.** The full image and
a barebones one holding the binary and nothing else, no git, no gh, no
ripgrep, print the same breakdown byte for byte. Installing fewer packages
saves megabytes and pull time, never tokens: Claude Code does not describe
its own tools according to what it finds on the PATH.

| Image                     | Size   | Context |
|---------------------------|--------|---------|
| Every tool installed      | 740 MB | 16.4k   |
| The binary alone          | 471 MB | 16.4k   |

**What you add does change it, and is itemised.** `/context` prices each
skill, each memory file and each MCP tool separately, and marks a skill as
yours or built in. Measured additions, on the same image:

| Addition                            | Tokens |
|-------------------------------------|--------|
| One user skill                      | 110    |
| A short project CLAUDE.md           | 55     |
| An MCP server exposing three tools  | 848    |

MCP tools are deferred in 2.1.273, so their schemas load on demand and stay
out of the loaded total. One blind spot is worth knowing: the instructions
a server declares when it connects did not show up in any category, even at
4,500 tokens, so `/context` under-reports a server that ships a long one.

**Removing the built-in skills costs more than it saves.** With
`disableBundledSkills`, the total rises from 16.4k to 24.9k. The Workflow
tool carries its authoring documentation in a built-in skill, loaded
on demand. Remove the skill and the tool inlines that documentation into
its own description. Cutting the single `workflow-authoring` skill
reproduces it exactly. The two only pay off together: `disableWorkflows`
alone saves 2.6k, and with the skills off 2.7k.

**The tool set is the only lever with mass.** `--tools` restricted to six
tools takes the floor from 16.4k to 8.5k, and `--tools ""` to 2.9k. That is
a different agent, not a lighter image, and the flag ignores user, project
and local settings files, so an image that bakes it locks the tool set for
everything built on top.

## License

To be decided.
