# Existing pull request

Run `./.agents/skills/kangentic-release-workflow/scripts/pull-request.sh status`. The PR, branch, and card—not session memory—
are authoritative.

- **OPEN:** apply `stage:reviewed wait:pr`; compare `headRefOid` with local
  `HEAD`; show URL, checks, review decision, and whether changes await update.
  Offer **Refresh status**, **Update PR**, **Apply feedback**, or **Keep waiting**.
- **MERGED:** offer **Finalize & Close**, **Inspect merge**, or **Keep open**.
  Finalize only through `finalize-pr.md` after explicit selection.
- **CLOSED without merge:** apply `stage:reviewed wait:pr-feedback`; never move
  Done. Show review/comments and offer **Revise in Implementation**, **Reopen
  PR**, **Park in Needs input**, or **Keep rejected**. Reopen only explicitly.

Use `AskUserQuestion` with header `PR`; accept free text. Never create a second
PR for the branch. A cold session reconstructs state from GitHub. If Update PR
is selected, perform the normal re-verification and release preparation before
calling the PR adapter.
