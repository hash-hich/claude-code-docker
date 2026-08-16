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

## Who it is for

- You run Claude Code in containers and want a smaller, faster image.
- You want a Claude Code setup you control end to end: agent version, tools,
  skills.
- You need one image for a team, and want every member to run the same thing.

## Status

Early stage. The project is being set up and nothing is buildable yet. This
README states the goal; the rest follows.

## License

To be decided.
