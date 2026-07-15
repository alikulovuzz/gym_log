# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in **`alikulovuzz/gym_log`**.

> **Note on tooling.** The `gh` CLI is **not installed** on this machine, and neither is `winget`. Use the **GitHub REST API via `curl`** instead. A working token is already stored in Git Credential Manager — retrieve it without printing it:
>
> ```bash
> export GH_TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n 's/^password=//p')
> curl -s -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
>   https://api.github.com/repos/alikulovuzz/gym_log/issues
> ```
>
> Never echo the token. If `gh` is installed later, the standard `gh issue …` commands below apply as written.

## Conventions

- **Create an issue**: `POST /repos/alikulovuzz/gym_log/issues` with `{title, body, labels}` (`gh issue create --title "..." --body "..."`)
- **Read an issue**: `GET /repos/alikulovuzz/gym_log/issues/<n>` plus `/comments` (`gh issue view <n> --comments`)
- **List issues**: `GET /repos/alikulovuzz/gym_log/issues?state=open` (`gh issue list --state open`)
- **Comment**: `POST /repos/alikulovuzz/gym_log/issues/<n>/comments` (`gh issue comment <n> --body "..."`)
- **Labels**: `PATCH` the issue's `labels`, or `POST /issues/<n>/labels` (`gh issue edit <n> --add-label "..."`)
- **Close**: `PATCH /repos/alikulovuzz/gym_log/issues/<n>` with `{"state":"closed"}` (`gh issue close <n>`)

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

`GET /repos/alikulovuzz/gym_log/issues/<n>` and its comments.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

Both GitHub **sub-issues** and **native issue dependencies** are confirmed working on this repo — use them; no body-convention fallback is needed.

- **Map**: an issue labelled `wayfinder:map`. The live one is **[Map: Gym-log app on the Xiaomi Smart Band 10](https://github.com/alikulovuzz/gym_log/issues/1)** (#1).
- **Child ticket**: a GitHub **sub-issue** of the map. Labels: `wayfinder:<type>` — one of `task`, `research`, `prototype`, `grilling` (all five labels exist on the repo). Once claimed, assign to the driving dev.
  - Link: `POST /repos/alikulovuzz/gym_log/issues/<map>/sub_issues` with `{"sub_issue_id": <child DB id>}` — the **numeric database id** (`.id`), *not* the `#number`.
- **Blocking**: native issue dependencies.
  - `POST /repos/alikulovuzz/gym_log/issues/<child>/dependencies/blocked_by` with `{"issue_id": <blocker DB id>}`.
  - Read the live gate from the issue's `issue_dependencies_summary.blocked_by` (counts **open** blockers only).
- **Frontier**: list the map's sub-issues (`GET /issues/1/sub_issues`), drop any that are closed, have an assignee, or have `issue_dependencies_summary.blocked_by > 0`. Lowest issue number wins.
- **Claim**: add the assignee — the session's **first** write, before any work.
- **Resolve**: post the answer as a comment, close the issue, then append a context pointer (gist + link) to the map's *Decisions so far*.
