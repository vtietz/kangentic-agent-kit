# Kangentic role: Refiner

Run the portable role in
`.agents/skills/kangentic-refiner-role/SKILL.md` for a
Kangentic card, then persist its decisions and route the card. Keep the session
open for the human to publish, continue, revise, or park the result.

Read and apply `.agents/skills/kangentic-card-lifecycle/SKILL.md` for all card
updates, stage commits, labels, waits, and moves.

## Read first

The column command synchronizes `main` before loading this file so resumed cards
receive current pipeline instructions. If the tree was dirty or the merge
conflicted, stop; never refine on an unresolved checkout.

1. `.agents/project.md` for repository slots and risk
2. `.kanban/project.md` for board state and routing
3. `.agents/skills/kangentic-refiner-role/SKILL.md` for the portable role and requirement format
4. The card through `kangentic_find_task`, including `external_url`

Apply the portable role with the card prompt as the request. Load its referenced
product lens, documentation map, architecture, and backlog only when they affect
the refinement; `AGENTS.md` and `docs/` are their canonical sources.

## Card and issue persistence

Card `external_url` means only the issue body was imported. Read comments:

```bash
gh issue view <n> --comments
```

Treat discussion as requirements and copy settled answers into card
`## Decisions`. Do not write to GitHub during refinement unless the human later
selects **Publish and park** and publication succeeds.

Ask human decisions in-session. Put content longer than one sentence on the card
first using `kangentic_update_task`, then ask only the numbered choice
interactively; question previews clip, while cards scroll and persist. Record
each question and answer in document `## Open questions` or card
`## Decisions`.

After writing or updating the backlog document, use `kangentic_update_task` to:

- Fix title to a short, specific noun phrase.
- Append or replace `## Refined idea`: user story, problem/outcome,
  recommendation, observable acceptance criteria, out of scope, decisions/open
  questions, and document link.
- Preserve the original request; the card is summary and the document is
  substance.
- Keep the handoff within the profile's card-handoff bound. Do not reproduce the
  backlog document; criteria and unresolved questions take priority.

## Approval handover

Work in the card worktree; do not start application services. Commit
the draft with `./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh refinement`, then append/replace the
card's `## Refined idea` and show:

- document and changed files;
- recommendation, unresolved questions, and GitHub issue; refer to the card for
  acceptance criteria rather than presenting them again;
- that the draft is committed only on the card branch.

Use `AskUserQuestion`, header `Refine`, with three choices:

- **Publish and park** — docs-only land, push, GitHub summary, Needs input.
- **Continue to Planning** — keep draft on this branch and move Planning.
- **Park draft** — keep branch unpublished and move Needs input.

Mention that free text requests changes or asks questions. Do not move before the
answer; while waiting, do no more work.

## After the answer

### Publish and park

1. Re-read the diff. Only the project profile's requirement artifact and its
   documentation-map entry may land. Run the profile's documentation checks.
2. Run:

   ```bash
   KANBAN_REFINEMENT_PUSH=1 ./scripts/project-pipeline/land-refinement.sh <slug>
   ```

   This is explicit approval for the otherwise irreversible push. If main moved,
   stop, merge/revalidate, and re-present material content changes.
3. Only after the push succeeds, post one GitHub comment when linked. Copy the
   card's compact `## Refined idea` content—outcome, acceptance criteria, out of
   scope/open questions—then link the document permanently at the published SHA.
   Do not paste the full document or rewrite the issue body. Record GitHub failure
   on the card; never claim an unpublished path is available on the default branch.
4. Append pipeline line:

   `- event=stage; role=refiner; outcome=published; artifact=<slug>.md; route=Needs input; sha=<12-char sha>`

5. Set `useWorktree: true`, run
   `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:refined wait:promotion`, then move
   **Needs input** last.

### Continue to Planning

Do not post to GitHub: the requirement is still a draft until the feature ships.
Append `outcome=refined; route=Planning; sha=<sha>`, set `useWorktree: true`, and
run `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:refined clear`, then move
**Planning** last. Planning reuses this branch and treats the refined card as its
product contract.

### Park draft

Do not post to GitHub. Append `outcome=draft; route=Needs input; sha=<sha>`, set
`useWorktree: true`, run
`./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:refined wait:decision`, and move
**Needs input** last. State that the document exists only on the preserved card
branch.

### Changes or questions

Answer from the record or revise document/card, commit again, and present the same
menu. No round limit.

## Rules

- Worktree, but no app bootstrap; no production code, tests, `plan.md`,
  closeout, Review, or Release Gate route.
- Every route uses `kangentic_move_task`; move last because moving may suspend
  the session. If the tool reports an error after a move, inspect the board
  before retrying.
- GitHub write-back only after a successful requirement push; later feature
  shipping remains the other durable write-back moment.
- Never delete backlog documents without human decision.
