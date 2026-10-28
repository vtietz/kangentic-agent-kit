---
name: kangentic-release-workflow
description: Prepare, present, and complete an explicitly approved release from a Kangentic card branch. Use for Release Gate handover, reviewed-SHA carry-forward, card squash or landing, PR preparation, final reporting, or cleanup; do not use before independent Review passes.
---

# Kangentic release workflow

Read `.agents/project.md` for repository hooks and `.kanban/project.md` for
release authority and card routing.
Read `kangentic-card-lifecycle` for persistence ordering and the repository
pull-request skill for GitHub operations.

## Prepare the human gate

- Reconstruct existing PR state before another handover.
- Require a clean tree and compare source against Review's verified SHA.
- Carry Review only when project-defined source paths are unchanged; otherwise
  run the profile's release verification before previewing.
- Read only Review's `## Verdict`, `## Checks`, and `## Release brief`, plus the
  closeout suggested commit message, learning candidate and `## Preview setup`.
  Start a running card preview for the first human handover, even when Review
  reports no human-visible risk, unless the human explicitly asks to skip it.
  Verify readiness and open/report the same URL; never improvise state. The card, not `plan.md`, supplies
  acceptance criteria.
- Present outcome, clicks, validation, base divergence, and exact commit subject.

Entering Release Gate is not authority to mutate GitHub or the base branch. Ask for
one explicit choice among PR publication, local landing, direct publication, or
waiting. Do not translate vague approval such as “looks good” into release.

## Execute one approved path

Resynchronize with the base and validate in proportion to incoming source
changes. Use only this skill's release scripts or the repository pull-request
skill; do not reproduce Git or GitHub mechanics manually.

After landing, write the repository's landed report, distribute it once, run the
cleanup hook, prove reachability from the intended base, persist the outcome,
and move Done last. An open PR remains in Release Gate; finalize only after GitHub
reports it merged. Inspect status before retrying any failed remote operation.
Shipping resolves any imported GitHub issue from the card's durable
`external_url` and refuses every release path when the squash commit lacks the
matching `Closes #<number>` footer.

The skill-owned scripts perform card shipping, pull-request composition,
reporting, and commit-message extraction. Use `scripts/ship.sh`,
`scripts/pull-request.sh`, `scripts/report.sh`, and `scripts/commit-message.sh`;
do not recreate their mechanics in a role prompt.

## Conditional playbooks

Load only the reference matching current durable state:

- `references/handover.md` — first arrival with no PR;
- `references/existing-pr.md` — an open, closed, or merged PR exists;
- `references/release.md` — explicit create-PR, local-land, or publish choice;
- `references/finalize-pr.md` — explicit finalization of a merged PR;
- `references/feedback.md` — questions or requested product changes; or
- `references/follow-ups.md` — explicitly requested follow-up or skill proposal.

Do not preload references for hypothetical later choices. Re-read card, branch,
and PR state before selecting a new playbook after human input.
