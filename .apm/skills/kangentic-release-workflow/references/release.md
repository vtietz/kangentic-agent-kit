# Execute an approved release

Require an explicit PR, local-land, or publish choice; “looks good” is not one.

1. Require a clean tree.
2. Merge the profile base branch and inspect incoming paths:

   ```bash
   git merge --no-edit main
   git diff --name-only HEAD@{1}..main
   ```

   Skip recheck only when incoming paths exclude every profile-defined source,
   test, locale, dependency, and agent-guidance path. Otherwise run the profile
   check and selected-browser hook. Route product failures to Implementation.
   For infrastructure failures, wait in Release Gate using the lifecycle waiting
   procedure; park in Needs input only explicitly or when the session is
   unavailable.
3. Add the profile changelog entry only when it adds requester-facing information
   beyond the commit subject or discloses a known gap. Follow the convention
   stated at the top of the changelog, which is the single source of that
   convention: one line, newest first, one sentence under 200 characters, with a
   shipped known gap as a clause after a `·`. Resist the pull to summarize the
   card here - the entry says what is different now, and the commit body and
   `docs/` hold why and how. Commit that stage.
4. Read the card `display_id` and title with `kangentic_find_task`, then pass
   both as `KANBAN_CARD_NUMBER=<n>` and `KANBAN_CARD_TITLE='<title>'`:

   - **Create/update PR:** `KANBAN_CARD_NUMBER=<n> KANBAN_CARD_TITLE='<title>' ./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh prepare`.
     Record URL, number, prepared SHA, and checks; apply `stage:reviewed wait:pr`;
     remain in Release Gate and load `existing-pr.md` on the next interaction.
   - **Land locally:** `KANBAN_CARD_NUMBER=<n> KANBAN_CARD_TITLE='<title>' KANBAN_SHIP_LAND=1 ./.agents/skills/kangentic-release-workflow/scripts/ship.sh`.
   - **Publish:** `KANBAN_CARD_NUMBER=<n> KANBAN_CARD_TITLE='<title>' KANBAN_SHIP_PUSH=1 ./.agents/skills/kangentic-release-workflow/scripts/ship.sh`.

Report immediately if the landed message differs from the approved message.

For local land or publish, write `landed.md` in the resolved card directory with commit,
requester-facing summary, compact acceptance result, validation, scope, merged
base divergence, post-merge checks, state, recovery SHAs, known gaps, and a link
to committed card artifacts. Summary, validation, and known gaps are mandatory.

Distribute once with `./.agents/skills/kangentic-release-workflow/scripts/report.sh`; run before direct publication
so attempted state survives push failure. Do not commit `landed.md`. Then run the
profile cleanup hook and prove the landed commit is an ancestor of the base.
Cleanup or reachability failure blocks Done.

Persist `landed` or `published`, apply the matching stage label, and move Done
last through the card-lifecycle skill.
