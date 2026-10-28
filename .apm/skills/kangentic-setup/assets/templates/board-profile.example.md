# Kangentic board profile

Always read `.agents/project.md` first. This overlay owns only card state,
persistence, routing, waiting, and release authority.

## Card state and handoffs

Base branch: `<branch>`. Artifacts: `.kanban/<card-id>/plan.md`,
`e2e-specs.txt`, `closeout.md`, and `review.md`. Requirement archive:
`<path or not applicable>`. Commit-message source: `<source>`.

Stage labels: `<labels>`. Wait labels: `<labels>`. Preserve all unrelated
labels. Normal artifact size targets: `<targets>`.

## Routes

| Outcome | Column |
|---|---|
| refined and approved | `<column>` |
| planned | `<column>` |
| implemented | `<column>` |
| review passed | `<column>` |
| needs an ordinary reply | remain in current working column |
| intentionally parked | `<column>` |
| released | `<column>` |

External issue, pull-request, landing, and publication mutations require
explicit human authority.

## Conditional loads

| Trigger | Read or apply |
|---|---|
| repository source, command, risk, or UI matter | matching slot in `.agents/project.md` |
| preview state or early checkpoint | `kangentic-preview-checkpoint` skill |
| release | `kangentic-release-workflow` skill |
| pipeline maintenance | repository agent-guidance source |
