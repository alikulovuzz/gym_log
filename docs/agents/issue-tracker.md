# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in **`alikulovuzz/gym_log`**.

> **Note on tooling.** The `gh` CLI **is installed and authenticated** — v2.96.0, logged in as `alikulovuzz` with `repo` scope. Use the standard `gh issue …` commands below as written.
>
> It lives at `C:\Program Files\GitHub CLI\gh.exe` (installed via Chocolatey) and *is* on the machine `Path`. But a shell started before the install inherits a stale environment and reports `gh: command not found` — prepend the directory for the session rather than concluding `gh` is missing:
>
> ```powershell
> $env:Path = "C:\Program Files\GitHub CLI;$env:Path"
> ```
>
> **Fallback — REST via `curl`.** Still valid, and still the *only* route for the sub-issue and dependency endpoints under "Wayfinding operations" below, which `gh issue` does not wrap. A working token is in Git Credential Manager; retrieve it without printing it:
>
> ```bash
> export GH_TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n 's/^password=//p')
> curl -s -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
>   https://api.github.com/repos/alikulovuzz/gym_log/issues
> ```
>
> Never echo the token.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..." --label "..."` (`POST /repos/alikulovuzz/gym_log/issues`)
- **Read an issue**: `gh issue view <n> --comments` (`GET /repos/alikulovuzz/gym_log/issues/<n>` plus `/comments`)
- **List issues**: `gh issue list --state open` (`GET /repos/alikulovuzz/gym_log/issues?state=open`)
- **Comment**: `gh issue comment <n> --body "..."` (`POST /repos/alikulovuzz/gym_log/issues/<n>/comments`)
- **Labels**: `gh issue edit <n> --add-label "..."` (`POST /issues/<n>/labels`)
- **Assign**: `gh issue edit <n> --add-assignee "..."` (`POST /issues/<n>/assignees`)
- **Close**: `gh issue close <n>` (`PATCH /repos/alikulovuzz/gym_log/issues/<n>` with `{"state":"closed"}`)

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

`gh issue view <n> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

Both GitHub **sub-issues** and **native issue dependencies** are confirmed working on this repo — use them; no body-convention fallback is needed.

**These endpoints are not wrapped by `gh issue`** — use `curl` (or `gh api`) for the sub-issue and dependency calls below.

- **Map**: an issue labelled `wayfinder:map`. The live one is **[Map: Gym-log app on the Xiaomi Smart Band 10](https://github.com/alikulovuzz/gym_log/issues/1)** (#1).
- **Child ticket**: a GitHub **sub-issue** of the map. Labels: `wayfinder:<type>` — one of `task`, `research`, `prototype`, `grilling` (all five labels exist on the repo). Once claimed, assign to the driving dev.
  - Link: `POST /repos/alikulovuzz/gym_log/issues/<map>/sub_issues` with `{"sub_issue_id": <child DB id>}` — the **numeric database id** (`.id`), *not* the `#number`.
- **Blocking**: native issue dependencies.
  - `POST /repos/alikulovuzz/gym_log/issues/<child>/dependencies/blocked_by` with `{"issue_id": <blocker DB id>}`.
  - Read the live gate from the issue's `issue_dependencies_summary.blocked_by` (counts **open** blockers only).
- **Frontier**: list the map's sub-issues (`GET /issues/1/sub_issues`), drop any that are closed, have an assignee, or have `issue_dependencies_summary.blocked_by > 0`. Lowest issue number wins.
- **Claim**: add the assignee — the session's **first** write, before any work.
- **Resolve**: post the answer as a comment, close the issue, then append a context pointer (gist + link) to the map's *Decisions so far*.
