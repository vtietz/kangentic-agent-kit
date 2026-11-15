---
name: kangentic-preview-checkpoint
description: Prepare a disposable pre-code design checkpoint, reusable preview, or optional early implementation checkpoint when a material human decision needs visual evidence.
---

# Kangentic preview checkpoint

Read `.agents/project.md`, `.kanban/project.md`, the card lifecycle skill, and the
card plan when one exists. Do not load this skill when no design artifact,
preview state, or early checkpoint is needed.

## Pre-implementation design checkpoint

Refiner or Planner may use this checkpoint only when text cannot settle one
material interaction, proportion, layout, or multi-state choice. Use a text
sketch first. Create HTML or another visual artifact only when interaction or
proportion is the question. Do not change production source, tests, migrations,
or application data.

Use the project profile's design-preview hook when available; otherwise attach a
portable artifact the human can open. Verify the URL or attachment before
presenting it. Add or replace card `## Design checkpoint` with the question,
recommended option, artifact, intentionally omitted behavior, and next route.
Commit only the repository-approved disposable artifact when the profile allows
it; never make the mock part of the acceptance contract or reference it from
`plan.md`.

Ask **Approve direction**, **Adjust mock**, **Continue without mock**, or
**Park**. Approval and continue-without-mock stay in the owning role so it can
finish Refinement or Planning. Adjust stays in the role and replaces the same
checkpoint. Park follows the lifecycle waiting procedure and routes Needs input
only when the human chooses durable parking. Record the decision under card
`## Decisions` and remove the resolved checkpoint before routing onward.

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
