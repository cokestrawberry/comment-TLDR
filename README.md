# comment-TLDR

Rewrites overly long comment blocks into one WHAT line, up to three WHY lines, and one line above
each step.

## Install

In a Claude Code session:

```text
/plugin marketplace add cokestrawberry/comment-TLDR
/plugin install comment-tldr@comment-tldr
```

From a shell, `claude plugin marketplace add cokestrawberry/comment-TLDR` and
`claude plugin install comment-tldr@comment-tldr` do the same. Auto-update is off for this
marketplace by default, so update with `claude plugin update comment-tldr@comment-tldr`.

## Usage

```text
/comment-tldr [scope]
```

The scope decides which comments are rewritten:

- None: every file tracked by git.
- A path or glob (`src/`, `**/*.py`): the matching files.
- A git range or commit (`main...HEAD`, `a1b2c3d`): the lines it adds or changes, compared
  against the merge base.
- A PR (`#123`, `pr123`, `pr#123`): the lines the PR adds or changes. It works in a temporary
  worktree and asks before committing and pushing to the PR. This scope needs the GitHub CLI
  (`gh`). A bare number is not read as a PR, since it could be a path or a commit hash.

The other scopes edit your current checkout, so start from a clean working tree: `git diff` then
shows only the plugin's changes, and `git restore .` undoes them.

A block of 4 or more lines keeps only what the code cannot show. Docstrings, doc comments on public
APIs, license headers, TODO and FIXME notes, generated files, and `vendor/` stay untouched, and no
content the original comment lacks is added. The skill runs only when you call it.
