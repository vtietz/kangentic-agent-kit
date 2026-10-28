---
name: kangentic-preview-checkpoint
description: Prepare a reusable Kangentic preview or optional early checkpoint. Use only when preview state is needed or the plan sets Early human checkpoint to yes.
---

# Kangentic preview checkpoint

Read `.agents/project.md`, `.kanban/project.md`, the card plan, and the card lifecycle skill. Do not
load this skill for `Preview setup: none` and `Early human checkpoint: no`.

The Planner declares state; the Implementer reuses or creates its idempotent
repository-owned setup command; Reviewer only checks the declaration; Release
executes it exactly. Reuse public or documented flows; do not use a scratch
script, invent data at Release Gate, or alter shared demo or seed data. Record
the command, actor, destination, and result in `closeout.md`.

When `Early human checkpoint: yes`:

1. Build only the coherent slice needed for the decision and run diagnostics,
   boot, and happy-path checks.
2. Run the declared setup, start `preview.sh`, and park the preview
   destination declared by the project profile on the decision screen. Add a
   screenshot only when it clarifies the state.
3. Commit the draft and record destination/login, interaction path, one
   decision, working and unfinished behavior, and sanity checks under
   `## Early preview`.
4. Set `stage:planned` plus `wait:decision`; ask **Continue and finish**,
   **Adjust draft**, **Replan**, or **Park**.

Continue finishes in Implementation. Adjust stays in Implementation; Replan
routes Planning; Park routes Needs input. Free text means Adjust unless it
clearly selects another option. Keep the preview running while awaiting an
answer; if the session is lost, reconstruct it from the card, plan, and setup.
