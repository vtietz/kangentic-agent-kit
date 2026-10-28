---
name: kangentic-card-lifecycle
description: Persist and route work safely in a repository-backed Kangentic card pipeline. Use when a Kangentic role updates card decisions or artifacts, commits a stage, changes pipeline labels, waits for input, or moves a card; do not use outside a Kangentic card session.
---

# Kangentic card lifecycle

Treat the card, committed artifacts, labels, and branch as durable state. Session
transcripts are not a handoff. Record decisions, questions, feedback, outcomes,
and the next route before ending or moving.

## Persist before routing

1. Write the role's artifact in `.kanban/<card-id>/` when it has one.
2. Update the card description additively with `kangentic_update_task`; replace a
   named section only to avoid duplicates.
3. Commit stage files with
   `./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh <stage>`.
4. Add exactly one compact event beneath the card's single existing
   `## Pipeline log` heading with role, round, outcome, checks or artifact count,
   route, and 12-character SHA. Use a description edit; never append another
   `## Pipeline log` heading. Replace superseded current-state sections instead
   of accumulating duplicates.
5. Apply destination stage/wait labels through
   `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh`.
6. Call `kangentic_move_task` last because moving may suspend the session.

Never combine a long description update and labels in one board call; labels may
be lost. Every finding, escalation, wait, or deferral needs a durable reason and
an unambiguous route.

## Waiting and resumption

Keep a waiting card in its current working column with its session open. Ask
through the runtime's interactive input mechanism and wait for the reply; do
not move the card merely because the reply, dependency, or runner recovery is
pending. Do not poll, repeat commands, or continue blocked work while waiting.
A question's elapsed waiting time does not authorize parking or guessing.

Before asking, add or replace one `## Waiting for you` section at the very top
of the card description, preserving the original request and pipeline log:

```markdown
## Waiting for you

- Reason: <specific decision, dependency, or failed command and observed error>
- Next action: <one question or exact action; options and recommendation when useful>
- Resume in: <current working column; what happens after the answer>
```

Use `wait:decision` for a human choice, `wait:dependency` for prerequisite work,
and `wait:pipeline` for a runner/infrastructure blocker. Preserve the highest
completed stage label. A label is only a category; the top section must explain
the actual cause without requiring an artifact or transcript. Record questions
in the role artifact too when one exists. Persist/commit current evidence before
waiting, but do not mark an incomplete stage complete or call
`kangentic_move_task`. Log an input outcome with the current column as its route.

Use **Needs input** for explicitly chosen parking, or a session that cannot
remain available for interaction (for example, an exited session). Record why
in-session continuation is unavailable and the exact resume column before
moving. A dependency does not automatically require parking; ask whether to
keep waiting or park. Never use To Do for parking.

After a reply, record the answer under `## Decisions` or the role's feedback
section. Remove the resolved `## Waiting for you` section and clear its wait
label; retain the pipeline log and historical evidence. Rerun failed required
checks after recovery before advancing. On resumption, read the latest artifact
and card section, classify the source as `initial`, `review`, or `human`, and
work only the required delta. A parked card retains the same visible summary
and resumes in its named role when the human returns it there.

## Safety invariants

- Work on the card branch, never commit directly to `main`.
- Do not install dependencies or override repository worktree isolation.
- A clean stage commit is a no-op; do not invent a change to create one.
- Move errors may mean suspension succeeded. Inspect board state before retrying.
- Publication, PR mutation, landing, and deletion require explicit authority
  from the owning role or workflow skill.

The project profile supplies commands, hooks, labels, columns, artifacts, and
risk rules. This skill owns lifecycle ordering, not project behavior.

Its `scripts/` directory owns portable card-directory resolution, stage commits,
pre-review handoff checks, pipeline-label replacement, and wall-clock timeout
mechanics. Stable root `scripts/kanban-*` adapters preserve existing board and
role entrypoints.
