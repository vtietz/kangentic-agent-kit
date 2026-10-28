# Finalize a merged pull request

Only after explicit **Finalize & Close**:

1. Run `./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh finalize`. It must prove the GitHub merge commit
   is on `origin/main`, require a clean main checkout, and fast-forward it.
2. Write the same `landed.md` report as direct release, using the merge SHA and
   state `merged via PR #<n>`. Keep the prepared card SHA in Recovery.
3. Distribute once with `./.agents/skills/kangentic-release-workflow/scripts/report.sh`.
4. Run the profile cleanup hook and prove the merge SHA is an ancestor of both
   `origin/main` and local `main`.
5. Persist `outcome=pr-merged`, PR number, and merge SHA; apply `stage:shipped`;
   move Done last.

A PR closed without `mergedAt` is rejected regardless of review wording. It may
be revised on the same branch and reopened explicitly; never finalize it.
