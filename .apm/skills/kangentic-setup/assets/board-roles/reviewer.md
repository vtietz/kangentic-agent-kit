# Kangentic adapter: Reviewer

Read and follow `.agents/skills/kangentic-reviewer-role/SKILL.md` first. This adapter adds only the
Kangentic mechanical gate, card persistence, loop control, and routing.

Read and apply `.agents/skills/kangentic-card-lifecycle/SKILL.md` for all card
updates, stage commits, labels, waits, and moves.

## Read the contract

Read `.agents/project.md`, `.kanban/project.md`, only their matching conditional resources,
`.kanban/<card-id>/plan.md`, `.kanban/<card-id>/closeout.md`, and the complete
diff:

```bash
git diff main...HEAD
```

The plan's `## Contract` is the independent acceptance contract. Do not call
`kangentic_find_task` during an ordinary review; Planning has already normalized
the card and the Reviewer should not pay to ingest its operational history.
Fetch it only when the artifacts explicitly identify unresolved human feedback.

`## Early preview` is evidence, never a substitute for verification. For an
existing review, capture the latest verified SHA before editing:

```bash
previous_verified="$({ sed -n 's/^- \*\*Verified at\*\* — `\([^`]*\)`.*/\1/p' \
  .kanban/<card-id>/review.md 2>/dev/null || true; } | tail -1)"
```

## Mechanical gate

Run this before reading the implementation in depth:

```bash
log=/tmp/kanban-check-<card-id>.log
./scripts/project-pipeline/bootstrap.sh
if ./.agents/skills/kangentic-card-lifecycle/scripts/timeout.sh 900 <check> >"$log" 2>&1 &&
  ./.agents/skills/kangentic-card-lifecycle/scripts/timeout.sh 600 <security scan> >>"$log" 2>&1; then
  check_status=0
else
  check_status=$?
fi
echo "check exit: ${check_status}"
if (( check_status == 0 )); then
  grep -E '(passed\.|passed \()$' "$log" | tail -n 8 || true
else
  grep -Ein '(^FAIL |(^|[[:space:]])(error|failed|failure|exception|assertion|expected|received|no tests found|not found|TS[0-9]+))' "$log" | tail -n 30 || true
  tail -n 30 "$log"
fi
(( check_status == 0 )) || exit "$check_status"
<plan commands>   # only once the line above printed exit 0
```

- `<check>` is the profile's repository-wide **check** command.
- `<security scan>` is the profile's **security scan** command. Triage its
  findings under the testing skill; a finding without a fix or a reasoned
  suppression is `mechanical`.
- `<plan commands>` are the targeted **Commands to run**, in order, including
  selected browser specs. Do not also run the profile's aggregate browser hook.
- Run full suites only when `AGENTS.md` requires them.
- Bootstrap's gitignored config and `review.md` are the only allowed writes.

The timeout and log are mandatory: a runner may lose a successful command's
status, while the log remains authoritative. Do not stream it with `tee`.
Read `$log` before classifying a failure as `pipeline`. A missing status alone
is not pipeline evidence; use that classification only when the log is also
incomplete or the timeout reports 124. Retry once only when the failure is
clearly transient.

- Product, source, or test failure: `mechanical`, route **Implementation**.
- Broken command, transport, runner, or infrastructure that prevents judgment,
  including a scanner that cannot fetch its rules or advisories:
  `pipeline`, stop verification and wait in **Review** using the lifecycle
  waiting procedure; record the failed command, evidence and exact recovery action.

Stop the review when the gate fails. On pass, immediately record
`git rev-parse HEAD` as **Verified at** and create `review.md` if needed.

## Return review

If the tree changed since the latest **Verified at**, rerun the gate, then:

```bash
test -n "$previous_verified"
git merge-base --is-ancestor "$previous_verified" HEAD
git diff "$previous_verified"..HEAD
```

Verify claimed fixes and write `## Round <n>`. Collapse a superseded round to
one line containing verified SHA, verdict, finding count, and route. Perform a
full reading pass when a correction touches the sharpest edge or a file not
named by the previous findings, and state why.

The project profile supplies the responsive gate, authorization base rate,
permission matrix, status-code and key-propagation rules, documentation map,
and learning-promotion criteria used by the canonical role. Never create preview
data. Missing or insufficient preview setup for a data-dependent flow is a
`mechanical` finding.

When agent guidance changes, load the profile's agent-guidance maintenance skill
and use it to distinguish registration defects from competing sources of truth.

## Loop cap

Before returning a third consecutive `CHANGES_REQUESTED` to Implementation,
summarize failed fixes and route **Planning**. Reset after PASS, Planning, or a
`source=human` Implementer line. A passing review always advances.

On `PASS`, add `## Release brief` after the clean areas. Keep it to three lines:

- **Human-visible risk** — `none`, or the one route/state a human should judge.
- **Preview** — `skip`, or setup command, actor, and destination.
- **Human check** — `none`, or the expected visible result in one sentence.

This is a file handover, not reviewer-session context. A `none` risk lets Release
Gate present validation and shipping choices without starting a preview.

## Persist and route

Write `.kanban/<card-id>/review.md` for correction and routing. A clean review
should stay within about 200 words:

```markdown
## Verdict
PASS or CHANGES REQUESTED — include winning route reason when findings differ

## Checks
- **Verified at** — `<git rev-parse HEAD>`
- **check** — pass/fail
- **security scan** — pass/fail
- plan-selected targeted tests — pass/fail/no browser risk

## Findings
- What; `file:line`; impact; `mechanical`, `design`, or `pipeline`.

## Checked and clean
- Grouped surfaces actively verified with no findings.

## Release brief
- **Human-visible risk** — `none` or route/state
- **Preview** — `skip` or setup; actor; destination
- **Human check** — `none` or expected result

## Learning review
- Optional verdict and compact proposal fields; omit when no candidate.
```

Then:

1. Run `./.agents/skills/kangentic-card-lifecycle/scripts/stage-commit.sh review`.
2. Append the card pipeline line with `kangentic_update_task`:
   `- event=stage; role=reviewer; round=<n>; outcome=<PASS|CHANGES_REQUESTED>; checks=<pass|fail>; findings=<n>; design=<n>; pipeline=<n>; route=<column>; sha=<12-char sha>`
3. Move last with `kangentic_move_task`:
   - Any blocking `pipeline`: persist the failed verification and use the lifecycle waiting procedure in **Review**; do not move or issue a pass. After recovery rerun the gate and selected tests. Explicit parking may route **Needs input** with the resume reason.
   - Otherwise any `design`: `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:implemented clear`, then **Planning**.
   - Otherwise any `mechanical`: `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:implemented clear`, then **Implementation**.
   - Green: `./.agents/skills/kangentic-card-lifecycle/scripts/labels.sh <card-id> stage:reviewed clear`, then **Release Gate**.

Design wins over mechanical. Every finding requires a routing label.

## Adapter boundaries

- Never edit source, tests, or configuration under review. The only exceptions
  are the project bootstrap hook output and `review.md`.
- Do not repeat the canonical review rules here; update
  the portable Reviewer role skill when portable Reviewer behavior changes.
