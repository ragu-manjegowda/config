# Commit Message Policy

When the user asks for a commit message, inspect the exact staged changes before
writing it. Use `git status --short` and `git diff --cached` so the message
describes only the staged patch.

Read recent full commit messages with `git log --format='%B'`. Do not rely only
on `git log --oneline`, because the subject alone does not show the repository's
body structure, indentation, sections, or sign-off convention.

Read `~/.config/git/gitmessage.txt` and use it as the minimum commit-message
structure. Match the style and component naming used by recent repository
history. The default response must be a complete multiline commit message in a
fenced text block, including:

- A repository-style subject line.
- `Details:` describing the staged implementation.
- `Resolves:` listing the concrete problems addressed.
- `Tests:` listing only verification that was actually performed.
- The repository's `Signed-off-by:` line when recent history uses it.

Do not respond with only an oneline subject unless the user explicitly requests
an oneline or subject-only message. Do not invent tests, results, issue numbers,
or behavior that cannot be established from the staged patch and completed
verification.

If the staged area contains unrelated concerns, point that out before proposing
a message and recommend splitting the commit. Do not stage or commit files
unless the user explicitly requests that action.
