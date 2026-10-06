---
name: comment-TLDR
description: >-
  Rewrites overly long code comment blocks in a scope (paths, a git range, or a PR number; the
  whole repository when omitted) into short summaries that keep only the essential content.
argument-hint: "[path | glob | git range | PR number]"
disable-model-invocation: true
---

# comment-TLDR

Rewrite overly long comment blocks so that people and AI agents alike can read them quickly.
Edit the files in place and change nothing but comments.

## Resolve the scope

Read `$ARGUMENTS` as one of the following, trying them in this order:

1. **Empty**: every file tracked by git in the repository (`git ls-files`).
2. **PR number** (`123` or `#123`): the lines the PR adds or changes (`gh pr diff <number>`). The
   PR's head branch must be checked out; if `gh pr view <number> --json headRefName` differs from
   the current branch, stop and tell the user.
3. **Path or glob**: every comment in the matching files.
4. **Git range or commit** (`main..HEAD`, `a1b2c3d`): the lines it adds or changes
   (`git diff <range>`, or `git show <commit>` for a single commit).

If an argument resolves to none of these, stop and name it. For a diff-based scope, a block is in
scope when any of its lines was added or changed; find it in the current file by its text, since
line numbers in the diff may have moved.

## Find candidate blocks

A block is one explanation, not one run of comment lines:

- Comment lines with no code line between them form one block, even when blank lines or empty
  comment lines separate them.
- A block that continues the previous block's explanation, instead of describing the code directly
  below it, belongs to that previous block even across code lines.

A block of explanatory prose with 4 or more lines is a candidate. Skip:

- API documentation that a documentation tool attaches to a declaration: docstrings, Javadoc,
  JSDoc, Doxygen, Go doc comments, and the like.
- License and copyright headers.

## Rewrite each candidate

Sort the block's content into three kinds:

- **WHAT**: what the code does.
- **WHY**: why it is implemented this way, such as hidden constraints, workarounds, or surprising
  behavior.
- **Steps**: a description of an n-step procedure.

Then rewrite it within these limits:

- WHAT takes 1 line and WHY up to 3 lines, WHAT first.
- Each step takes 1 line, placed directly above the code for that step.
- Carry over only what the original comment says. Never add a WHAT, WHY, or step line it lacks: a
  comment without WHAT stays WHY-only, and steps it does not describe get no comments.
- Drop whatever does not fit, without saving it to chat, docs, or commit messages.
- Leave a block that already meets these limits untouched, such as 1 WHAT line plus 3 WHY lines.
- Split a block only so that each resulting block describes the code directly below it; never cut
  one explanation into consecutive chunks.

For the blocks this skill rewrites, these limits take precedence over any other comment-length
rule, such as a three-line maximum.

Keep each comment's language, comment syntax, and indentation.

## Line width

- Use the line length the repository configures, such as `.editorconfig` `max_line_length`,
  Prettier `printWidth`, Black or Ruff `line-length`, clang-format `ColumnLimit`, or rustfmt
  `max_width`. Without one, use 100 columns.
- Count the whole line, including indentation and the comment marker.
- Count a character whose Unicode East_Asian_Width is W or F, such as Hangul, as 2 columns.
- When a summary does not fit, shorten the wording instead of wrapping onto another line.

## Example

Before:

```python
def sync_index(cache):
    # Synchronize the local cache with the remote index.
    # First fetch the full index from the server, then compare it with
    # the local entries, and finally write only the entries that changed.
    #
    # The full index is fetched every time because the server sends no
    # ETag, so there is no way to ask for only the changes. Last-Modified
    # does not help either: the server sets it to the request time, so
    # conditional requests never hit.
    index = fetch_index()
    changed = diff(index, cache.entries())
    cache.write(changed)
```

After:

```python
def sync_index(cache):
    # Sync the local cache with the remote index.
    # The server sends no ETag and sets Last-Modified to the request time,
    # so conditional requests never hit and the full index is fetched each time.
    # Fetch the full index.
    index = fetch_index()
    # Compare it with the local entries.
    changed = diff(index, cache.entries())
    # Write only the changed entries.
    cache.write(changed)
```

## Report

List each rewritten block as `path:line`. Do not quote the removed text.
