# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in **`alikulovuzz/gym_log`**.

> **Note on tooling.** The `gh` CLI **is now installed**, as a no-admin portable build at
> `~/tools/gh/bin/gh.exe` (v2.96.0), authenticated as `alikulovuzz` with `repo` scope via the
> token already in Git Credential Manager.
>
> It is **not on the persistent `PATH`** — add it per-session:
>
> ```bash
> export PATH="$HOME/tools/gh/bin:$PATH"
> gh issue list --repo alikulovuzz/gym_log
> ```
>
> The GitHub REST API via `curl` remains a working fallback (`winget` is still absent; `choco`
> exists but needs elevation):
>
> ```bash
> export GH_TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n 's/^password=//p')
> curl -s -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
>   https://api.github.com/repos/alikulovuzz/gym_log/issues
> ```
>
> Never echo the token.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`
- **Read an issue**: `gh issue view <n> --comments`
- **List issues**: `gh issue list --state open`
- **Comment**: `gh issue comment <n> --body "..."`
- **Labels**: `gh issue edit <n> --add-label "..."`
- **Close**: `gh issue close <n>`

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

`gh issue view <n> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

Both GitHub **sub-issues** and **native issue dependencies** are confirmed working on this repo — use them; no body-convention fallback is needed.

- **Map**: an issue labelled `wayfinder:map`. The live one is **[Map: Gym-log app on the Xiaomi Smart Band 10](https://github.com/alikulovuzz/gym_log/issues/1)** (#1).
- **Child ticket**: a GitHub **sub-issue** of the map. Labels: `wayfinder:<type>` — one of `task`, `research`, `prototype`, `grilling` (all five labels exist on the repo). Once claimed, assign to the driving dev.
  - Link: `gh api repos/alikulovuzz/gym_log/issues/<map>/sub_issues -f sub_issue_id=<child DB id>` — the **numeric database id** (`.id`), *not* the `#number`.
- **Blocking**: native issue dependencies.
  - `gh api repos/alikulovuzz/gym_log/issues/<child>/dependencies/blocked_by -f issue_id=<blocker DB id>`.
  - Read the live gate from the issue's `issue_dependencies_summary.blocked_by` (counts **open** blockers only).
- **Frontier**: list the map's sub-issues (`gh api repos/alikulovuzz/gym_log/issues/1/sub_issues`), drop any that are closed, have an assignee, or have `issue_dependencies_summary.blocked_by > 0`. Lowest issue number wins.
- **Claim**: add the assignee — the session's **first** write, before any work.
- **Resolve**: post the answer as a comment, close the issue, then append a context pointer (gist + link) to the map's *Decisions so far*.
