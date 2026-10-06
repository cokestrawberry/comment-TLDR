---
name: comment-tldr
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
2. **PR number** (`123` or `#123`): the lines the PR adds or changes (`gh pr diff <number>`),
   rewritten in a temporary worktree as described in [Work on a PR](#work-on-a-pr).
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

- Docstrings, such as Python's, at any visibility. They are string literals the program keeps at
  runtime, and doctest runs the examples in them.
- Doc comments on public API declarations: exported Go names, public or protected Java, Kotlin,
  and C# members, exported JS and TS declarations, `pub` Rust items, and the like. When visibility
  is unclear, as in C and C++, treat the declaration as public.
- License and copyright headers.

Doc comments on other declarations are ordinary comments.

Leave the following exactly as they are. They do not count toward a block's length or the limits
below:

- TODO and FIXME notes, continuation lines included.
- In doc comments: tag lines such as `@param`, `@return`, and `\param`, deprecation notices such as
  Go's `Deprecated:` paragraph, and code examples.

## Rewrite each candidate

Sort the block's content into three kinds:

- **WHAT**: what the code does.
- **WHY**: why it is implemented this way, such as hidden constraints, workarounds, or surprising
  behavior.
- **Steps**: a description of an n-step procedure.

Then rewrite it within these limits:

- WHAT takes at most 1 line and WHY at most 3 lines, WHAT first.
- Each step takes 1 line, placed directly above the code for that step.
- Drop a WHAT or step line that only restates the single statement directly below it.
- Carry over only what the original comment says. Never add a WHAT, WHY, or step line it lacks: a
  comment without WHAT stays WHY-only, and steps it does not describe get no comments.
- Drop whatever does not fit, without saving it to chat, docs, or commit messages. Keep
  constraints that cannot be read from the code first; drop alternatives that were considered and
  the history of how the code got here first.
- Leave a block that already meets these limits untouched, such as 1 WHAT line plus 3 WHY lines.
- Split a block only so that each resulting block describes the code directly below it; never cut
  one explanation into consecutive chunks.

For the blocks this skill rewrites, these limits take precedence over any other comment-length
rule, such as a three-line maximum.

Keep each comment's language, comment syntax, and indentation.

## Line width

- Use the line length the repository's formatter or linter enforces, including a tool's default
  when the repository runs it without configuring one. Without either, use 100 columns.
- Count the whole line, including indentation and the comment marker.
- Count a character whose Unicode East_Asian_Width is W or F, such as Hangul, as 2 columns.
- When a summary does not fit, shorten the wording instead of wrapping onto another line.

## Examples

A comment inside a function body. Before:

```python
def sync_index(cache):
    # Synchronize the local cache with the remote index.
    # First fetch the full index from the server and parse its entries,
    # then find the entries that differ from the local ones, and finally
    # write those entries back to the cache.
    #
    # The full index is fetched every time because the server sends no
    # ETag, so there is no way to ask for only the changes. Last-Modified
    # does not help either: the server sets it to the request time, so
    # conditional requests never hit. We settled on this in the March sync
    # review as the simplest option that works.
    raw = http.get(INDEX_URL).json()
    index = {e["id"]: Entry(e) for e in raw["entries"]}
    changed = []
    for entry in index.values():
        if cache.get(entry.id) != entry:
            changed.append(entry)
    cache.write(changed)
```

After. The last step is dropped because `cache.write(changed)` already says it:

```python
def sync_index(cache):
    # Sync the local cache with the remote index.
    # The server sends no ETag and sets Last-Modified to the request
    # time, so conditional requests never hit and the full index is
    # fetched every time.
    # Fetch and parse the full index.
    raw = http.get(INDEX_URL).json()
    index = {e["id"]: Entry(e) for e in raw["entries"]}
    # Find the entries that differ from the local ones.
    changed = []
    for entry in index.values():
        if cache.get(entry.id) != entry:
            changed.append(entry)
    cache.write(changed)
```

A doc comment on an unexported Go function. Before:

```go
// syncIndex synchronizes the local cache with the remote index.
// The server sends no ETag, and Last-Modified is set to the request time,
// so conditional requests never hit and the full index is fetched every
// time. An earlier version polled the server's change feed, which was
// removed in v2. We settled on this in the March sync review as the
// simplest option.
//
// Deprecated: use syncIndexV2, which sends conditional requests.
func syncIndex(c *Cache) error {
```

After. The same comment on an exported `SyncIndex` would stay untouched:

```go
// syncIndex synchronizes the local cache with the remote index.
// The server sends no ETag and sets Last-Modified to the request time,
// so conditional requests never hit and the full index is fetched every time.
//
// Deprecated: use syncIndexV2, which sends conditional requests.
func syncIndex(c *Cache) error {
```

## Report

List each rewritten block as `path:line`. Do not quote the removed text.

## Work on a PR

Leave the current checkout as it is and work in a temporary worktree:

1. Run `git fetch origin pull/<number>/head`, then
   `git worktree add -b comment-tldr/pr-<number> .claude/worktrees/comment-tldr/pr-<number>
   FETCH_HEAD`. If that branch or path already exists from an earlier run, stop and give its path.
2. Rewrite comments inside that worktree only, then report as above.
3. Ask the user whether to commit the changes and push them to the PR. The target is the
   `headRefName` branch in the `headRepository` that `gh pr view <number> --json
   headRefName,headRepository` returns.
4. On yes, commit only the files this skill changed, with a message in the style of the
   repository's recent commits, push, and remove the worktree and its branch. On no, or when the
   push fails, keep the worktree and give its path.
