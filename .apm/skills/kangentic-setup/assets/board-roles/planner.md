# Kangentic adapter: Planner

Read and follow `.agents/skills/kangentic-planner-role/SKILL.md` first. This adapter adds only card
normalization, durable questions, planning artifacts, loop control, commits, and
routing.

Read and apply `.agents/skills/kangentic-card-lifecycle/SKILL.md` for all card
updates, stage commits, labels, waits, and moves.

## Read the card

Read `.agents/project.md`, `.kanban/project.md`, only their matching conditional resources, and the
card. Card `## Decisions` are binding. Set pipeline `source` to `initial`,
`review`, or `human`.

Inspect existing branch work:

```bash
git log --oneline main..HEAD
git diff main...HEAD --stat
```

A nonempty diff is returned work. Human feedback overrides earlier plans. Plan
the delta—what stays, changes, and is removed—without parallel implementations.

## Normalize the requirement

Do not repeat Refinement when `## Refined idea` is sufficient. Otherwise use
`kangentic_update_task` to add or replace one concise section containing user
story, assessment, decisions, observable criteria, out of scope, affected
surface, and docs impact. Preserve the original request and correct the title to
a short noun phrase.

For an imported issue, read comments with `gh issue view <n> --comments` and
record settled answers. Verify dated backlog claims against code. If the work is
not worth building, record why and route **Refinement**, which owns backlog and
external write-back.

## Questions

Ask observable questions with options, recommendation, and trade-offs; record
answers under `## Decisions`. If unanswered, record numbered `## Open questions`
(also atop an existing plan), then follow the lifecycle skill’s visible waiting
summary and interactive wait in **Planning**. Use `wait:dependency` when a
prerequisite blocks the plan; state its exact completion condition. Do not
invent an undefined collection period or move merely because a reply is pending.
Use a mock only when text cannot decide an interaction or proportion; it must
resolve a specific question and must not be referenced by `plan.md`.

## Planning artifacts

Write `.kanban/<card-id>/plan.md` using the canonical role's output and map the
project-profile slots:

- Load only the project profile's matching sharpest-edge, documentation, and
  responsive resources.
- Use exact command-table commands and preserve their path bases.
- Set **Early checkpoint** to `yes` only for one material human decision before
  hardening. The exact `human-preview` label forces `yes`; otherwise default to
  `no`.
- Preview may be `none` only when empty state exposes the acceptance behavior;
  otherwise name a reusable idempotent command, destination, actor, and state.
- Preserve the refined idea's marketing-scene decision when present; a `yes`
  adds the scene and the profile's visual-scene command, otherwise `no`.

Write `.kanban/<card-id>/e2e-specs.txt` with repository-relative browser specs,
one per line; comments and an empty file are valid. Batch selected specs into
one command. The plan is an execution contract, not an investigation diary.

## Loop cap

Before a third consecutive `source=review` replan, summarize what the failed
plans disagreed about and ask the human in **Planning** using the lifecycle
waiting procedure. Do not replan again until the reply arrives. Initial and
human-driven plans do not count and reset the streak.

## Persist and route

For deferral, log `outcome=deferred; specs=0; route=Refinement`, clear labels,
move Refinement, and create no planning artifacts.

In the main checkout, do not commit; report files for human review.

Otherwise, in order:

1. Run `./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh planning`.
2. Append one card `## Pipeline log` entry with `kangentic_update_task`:
   `- event=stage; role=planner; round=<n>; source=<initial|review|human>; outcome=<planned|deferred|input>; specs=<n>; route=<column>; sha=<12-char sha>`
3. Move last with `kangentic_move_task`:
   - unblocked refined idea and plan → `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:planned clear`, then **Implementation**;
   - open questions or dependencies → persist the current evidence, use the lifecycle waiting procedure, and stay in **Planning**; do not execute the move step. Explicit parking may route **Needs input** with a visible resume reason;
   - deferred → `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> keep clear`, then **Refinement**.

Do not write or propose the squash commit message; Implementer owns it in
`closeout.md`.

## Adapter boundary

Do not repeat portable design, test-selection, or plan-quality rules here.
Update the portable Planner role skill or the relevant development/testing skill.
