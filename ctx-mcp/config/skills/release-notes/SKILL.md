---
name: release-notes
description: Write the release notes for a version from the commits it contains. Use when the user asks for release notes, a changelog entry, or a summary of what shipped in a tag.
---

# Release notes

Read the commits between the previous tag and this one, then group them by
what a reader of the notes cares about.

1. List the commits with `git log --oneline <previous>..<current>`.
2. Drop anything invisible from outside: refactors, test changes, chores.
3. Group what is left into fixes, features and breaking changes.
4. Write one line per entry, in the past tense, naming the user visible
   effect rather than the code that changed.
