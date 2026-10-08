# comment-TLDR

Plugin for Claude Code and Codex that rewrites overly long comment blocks into one WHAT line, up
to three WHY lines, and one line above each step.

## Install

### Claude Code

```sh
claude plugin marketplace add cokestrawberry/comment-TLDR
claude plugin install comment-tldr@comment-tldr
```

In a Claude Code session, `/plugin marketplace add cokestrawberry/comment-TLDR` and
`/plugin install comment-tldr@comment-tldr` do the same. Auto-update is off for this marketplace
by default, so update with `claude plugin update comment-tldr@comment-tldr`. The new version loads
in your next session, or after `/reload-plugins` in a running one.

### Codex

```sh
codex plugin marketplace add cokestrawberry/comment-TLDR
codex plugin add comment-tldr@comment-tldr
```

## How to use

In Claude Code, run:

```text
/comment-tldr [scope]
```

In Codex, run:

```text
$comment-tldr:comment-tldr [scope]
```

The scope decides which comments are rewritten:

- None: every file tracked by git.
- A path or glob (`src/`, `**/*.py`): the matching files.
- A git range (`main...HEAD`): the lines it adds or changes, compared against the merge base.
- A commit (`a1b2c3d`): the lines it adds or changes.
- A PR (`#123`, `pr123`, `pr#123`): the lines the PR adds or changes. It works in a temporary
  worktree and asks before committing and pushing to the PR. This scope needs the GitHub CLI
  (`gh`). A bare number is not read as a PR, since it could be a path or a commit hash.

The other scopes edit your current checkout, so start from a clean working tree: `git diff` then
shows only the plugin's changes, and `git restore :/` undoes them.

A block of 4 or more lines is cut to one WHAT line, up to three WHY lines, and one line per step,
dropping alternatives and history before constraints the code cannot show. A block already within
those limits is left as it is. Docstrings, doc comments on public APIs, license headers, TODO and
FIXME notes, generated files, and `vendor/` stay untouched, and no content the original comment
lacks is added. The skill runs only when you call it.

## Evaluate

The cases in [plugins/comment-tldr/evals](plugins/comment-tldr/evals) score the skill with
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), which needs Claude Code
v2.1.269 or later. Each case writes fixture files, some in a git repository, with a scaffold
script, runs `/comment-tldr` on them, and checks the rewritten files, and for the git scopes the
session trace, with regex graders. Every run calls the model on your account.

```sh
claude plugin eval plugins/comment-tldr --scaffold --ablation none --no-publish \
  --allow-tools Edit "Bash(git *)" --model claude-opus-5-5
```

`--scaffold` runs the scaffold scripts, and `--allow-tools Edit "Bash(git *)"` lets the skill
rewrite the fixtures and run git. Git runs in Claude Code's
[sandbox](https://code.claude.com/docs/en/sandboxing), which needs `bubblewrap` and `socat` on
Linux, and on Ubuntu 24.04 or later an AppArmor setting that lets bubblewrap create user
namespaces. `--ablation none` skips the no-plugin baseline, since `/comment-tldr` does not exist
without the plugin. `--model` pins the model under test, so a model rollout is not mistaken for a
skill regression. Results are written to `plugins/comment-tldr/evals/results/`.

The git range, commit, and empty-scope cases are built to fail when git cannot run in that sandbox.
On a Mac that uses the Command Line Tools' `/usr/bin/git`, git has exited there with
`xcode-select: Failed to locate 'git'`; the
[eval workflow](.github/workflows/claude-plugin-eval.yml) runs the cases on Linux.

The cases do not cover the PR scope, which commits and pushes to a pull request: eval runs have no
GitHub credentials.

## Sponsor

[![Sponsor](https://img.shields.io/badge/Sponsor-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/cokestrawberry)

You can support comment-TLDR through GitHub Sponsors.
