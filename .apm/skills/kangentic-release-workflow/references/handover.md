# Release handover

## Establish current state

Report without merging:

```bash
git status --porcelain
git log --oneline main..HEAD
git log --oneline HEAD..main
comm -12 <(git diff --name-only main...HEAD | sort) \
         <(git diff --name-only HEAD..main | sort)
```

A dirty tree blocks handover. Delete an untracked file only when it is
byte-identical to `main`; never guess about other edits.

Read `review.md` **Verified at** and compare project-defined source paths:

```bash
git diff --name-only <verified-at-sha> HEAD -- ':(exclude).kanban/'
```

When source is unchanged, carry Review. Otherwise run the profile check and
selected-browser hook. Product/test failure routes Implementation;
runner/infrastructure failure waits in Release Gate using the lifecycle waiting
procedure; Needs input requires explicit parking or an unavailable session. Do not preview broken work.

## Prepare the human handover

Read Review's `## Release brief` and closeout `## Preview setup`. Run the
profile preview hook on first arrival unless the human explicitly opts out.
`Human-visible risk: none` does not waive the running preview. A `none` setup
means no extra seed command, not no application instance. Execute declared
setup exactly; never improvise data or endpoints.

Use the host URL printed by the preview hook for this card's worktree, then
combine it with the declared feature path. Do not calculate another port,
reuse a prior card's address, or assume the browser pane's default/saved URL is
correct. Verify both frontend and API readiness before saying the preview is
running. Open that exact destination with `kangentic_browser_open_pane` and
navigate to the feature with the declared actor; verify the pane displays the
same host/port/path you report. If browser tooling is unavailable, report that
limitation and give the verified clickable URL for manual navigation.

Present the running feature URL, actor/login instructions and the fewest useful
clicks before asking for a release choice. Keep the preview running while the
human inspects or waits, including while a PR stays open, unless they ask to
stop it. Apply the profile responsive gate to changed UI. For visual work,
attach after and—if practical without risky stash—before; otherwise state why
it is absent.

Missing, failing, or insufficient setup becomes card `## Preview setup gap` and
routes Implementation. Do not present a release-ready menu with an unavailable required preview.

## Persist the handover

Append a compact `## Ready to look at` containing:

- Review's human-visible risk and expected result;
- preview URL, actor/login, parked screen, and click path, or `preview skipped at the human’s request`;
- preview-setup command and state, or `skip`;
- optional before/after attachments;
- base divergence and overlapping files;
- carried or rerun checks;
- exact proposed commit subject, scope, and linked issue;
- requester-language outcome and bug cause/fix when applicable;
- the fewest clicks exercising human-visible risk; and
- validated learning proposal or `none`.

Keep within the profile handoff bound. Derive clicks from card acceptance
criteria, not the plan. Verify imported-issue messages end
`Closes #<issue-number>` from `external_url`, never the card display number.

Then ask once with header `Release`:

- **Create PR & Wait**
- **Publish & Close**
- **Land & Close**
- **Keep open**

This choice is confirmation; do not reconfirm unless synchronization or checks
change the state. Mention free text accepts questions, corrections, follow-ups,
and stop-preview requests. Wait without further checks, output, or moves.
