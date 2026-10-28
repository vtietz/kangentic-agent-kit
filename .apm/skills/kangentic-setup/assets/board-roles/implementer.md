# Kangentic adapter: Implementer

Read and follow `.agents/skills/kangentic-implementer-role/SKILL.md` first. This adapter adds only
Kangentic plan fallback, preview checkpoints, card artifacts, commits, and
routing.

Read and apply `.agents/skills/kangentic-card-lifecycle/SKILL.md` for all card
updates, stage commits, labels, waits, and moves.

## Read the contract

Read `.agents/project.md`, `.kanban/project.md`, only their matching conditional resources, and
`.kanban/<card-id>/plan.md`. Its `## Contract` is authoritative for planned work.
Do not call `kangentic_find_task` on an ordinary initial or Review-driven run:
the card contains human-visible history that the plan has already normalized.
Read the full card only when no planned contract exists for a direct-entry task,
or when returning human feedback is not captured in an artifact. A `## Fast lane
brief` is a compact scope anchor for a direct request, not a set of invented
acceptance criteria. Record plan conflicts in `closeout.md`. An unanswered
`## Open questions` means the card is not ready.

Run `./scripts/project-pipeline/bootstrap.sh`; do not install dependencies. Start
`closeout.md` immediately and update it throughout. Inspect existing branch work
with `git diff main...HEAD --stat` and implement the plan as a delta rather than
retaining duplicate solutions. Never set the project profile's worktree
isolation variable.

Determine the pipeline `source` from the incoming card: `initial`, `review`, or
`human`.

## Fast-lane direct entry

A narrow card may enter Implementation directly when its intended result and
scope can be established without a human choice. It may fix an API, schema, or
authorization defect; route to **Planning** only when the design, impact, or
safe behavior remains unclear. Before coding:

1. Preserve the card text. Write `## Fast lane brief` in
   `.kanban/<card-id>/plan.md`: intent, observable result, discovered scope,
   sharpest risk (or `none`), and validation. One short line each; do not derive
   detailed product criteria or promise unrequested polish.
2. Write `.kanban/<card-id>/e2e-specs.txt`; empty is valid.
3. Add `## Self-planned` to the closeout so Review knows the plan is not
   independent evidence.

Route to **Planning** when the summary cannot carry a safe technical decision or
the work becomes broader than the brief.

## Returning work

- From **Needs input**, read the latest `## Early preview` decision, reconstruct
  its branch and preview, and apply only a small in-scope delta. Changed behavior
  or criteria routes Planning.
- From **Review** or **Release Gate**, read the latest `review.md` round and `## Human
  feedback`. Apply only named corrections, append `## Correction round <n>`, and
  add one `## Correction response` line (finding, change, validation),
  then rerun affected validation. A plan or criteria change requires
  `## Escalation` and Planning.

Green corrections always return to independent Review. Never ask the human to
choose whether to skip it.

## Optional preview checkpoint

Default `Early human checkpoint: no` does not load preview instructions. When a
preview needs state or the checkpoint is `yes`, read and apply
`.agents/skills/kangentic-preview-checkpoint/SKILL.md`.

## Complete and route

Follow the canonical role and the plan, including planned commands, responsive
evidence, migrations, documentation, and preview setup. Use only project-profile
commands. Review owns the repository-wide check under the testing skill's split;
run it here only when the work is broad, the boundary is unclear, or diagnosis
requires it. Record whether it ran or was deferred.

Then:

1. Run `./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh implementation`.
2. Run `./.agents/skills/kangentic-card-lifecycle/scripts/pre-review.sh .kanban/<card-id> <source>`.
   Repair any missing handoff artifact or correction response before continuing.
3. Append one card pipeline line:
   `- event=stage; role=implementer; round=<n>; source=<initial|review|human>; outcome=<built|corrected|input|blocked>; commands=<n>; fixed=<n>; green=<yes|no>; route=<column>; sha=<12-char sha>`
4. Copy nonempty closeout `## Open problems` to the card.
5. Move last with `kangentic_move_task`:
   - `## Escalation` → **Planning**.
   - Complete closeout and green planned commands → run
     `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:implemented clear`, then **Review**.
   - Infrastructure, runner, or health failure → record `## Open problems`, run
     `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> keep wait:pipeline`, and route for
     human input in **Implementation** using the lifecycle waiting procedure; do
     not move while awaiting recovery. Never hand known red state to Review.

## Closeout artifact

Write `.kanban/<card-id>/closeout.md` as an exception-and-evidence handoff, not a
build diary. Aim for 200 words and record final runs only:

```markdown
## Commands run
- `<final authoritative command>` — pass/fail; key result

## Commands not run
- Only a plan- or policy-required command — why; otherwise `none`

## Docs updated
- `docs/...` — one-line durable change

## Preview setup
- `<command>` — destination, actor/login, pass/fail; or `none`

## Choices
- Non-obvious choice or deviation: decision; reason; rejected alternative

## Correction response
- Only for `source=review`: finding; changed file; validation rerun

## Open problems
- Unresolved failure, plainly stated

## Learning candidate
- Optional profile fields; omit when already corrected or card-specific

## Suggested commit message

feat(scope): imperative subject
```

The release skill's `scripts/ship.sh` uses the suggested conventional commit message
verbatim. For an imported issue, end its body with `Closes #<issue-number>` from
`external_url`; never derive it from the board card number. Without
`external_url`, do not add `Closes` or duplicate requirements into the issue.

## Adapter boundaries

- Do not repeat general implementation, testing, or shortcut rules here; update
  the portable Implementer role skill or the profile's testing skill instead.
- Report every failure accurately and never route a known red state to Review.
