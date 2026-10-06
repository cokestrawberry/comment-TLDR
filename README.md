# comment-TLDR

Rewrites overly long comment blocks into one WHAT line, up to three WHY lines, and one line above
each step.

## Evaluate

The cases in [plugins/comment-tldr/evals](plugins/comment-tldr/evals) score the skill with
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), which needs Claude Code
v2.1.269 or later. Each case writes a fixture file with a scaffold script, runs `/comment-tldr` on
it, and checks the rewritten file with regex graders. Every run calls the model on your account.

```sh
claude plugin eval plugins/comment-tldr --scaffold --ablation none --no-publish \
  --allow-tools Edit
```

`--scaffold` runs the scaffold scripts, and `--allow-tools Edit` lets the skill rewrite the
fixtures. `--ablation none` skips the no-plugin baseline, since `/comment-tldr` does not exist
without the plugin. Results are written to `plugins/comment-tldr/evals/results/`.

The cases do not cover the PR scope, which commits and pushes to a pull request: eval runs have no
GitHub credentials.
