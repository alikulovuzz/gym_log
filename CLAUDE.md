# CLAUDE.md

Guidance for agents working in this repo.

## Agent skills

### Issue tracker

Issues and PRDs live as **GitHub issues in `alikulovuzz/gym_log`** (REST API via `curl`; `gh` not installed). See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` + `docs/adr/` at the repo root (created lazily by `/domain-modeling`). See `docs/agents/domain.md`.
