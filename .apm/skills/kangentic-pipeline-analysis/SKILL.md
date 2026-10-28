---
name: kangentic-pipeline-analysis
description: Reassess a Kangentic pipeline using read-only card, session, token, cost, timing, and artifact evidence. Use for pipeline audits, before/after comparisons, expensive-session diagnosis, or detailed investigation of existing cards; do not use to mutate cards, sessions, profiles, or the Kangentic database.
---

# Kangentic pipeline analysis

Produce an evidence-backed assessment, not an automatic retuning. Keep analysis
read-only unless the user separately authorizes a pipeline change.

## Choose the evidence path

Prefer Kangentic's read-only tools when available:

- board and card state: `kangentic_board_summary`, `kangentic_find_task`,
  `kangentic_search_tasks`, and `kangentic_list_board_profiles`;
- resource use: `kangentic_get_usage_stats`, `kangentic_get_task_stats`, and
  `kangentic_get_activity_intervals`;
- session detail: `kangentic_list_sessions`, `kangentic_get_session_history`,
  and, only when rationale is required, `kangentic_get_transcript`.

Tool availability varies by Kangentic build. Do not invent a result when a tool
is absent. For historical aggregates, cache composition, transcript sizes, or
when the MCP server is unavailable, read
[references/database.md](references/database.md) and run the bundled report:

```bash
./.agents/skills/kangentic-pipeline-analysis/scripts/report.sh summary
./.agents/skills/kangentic-pipeline-analysis/scripts/report.sh summary 2026-08-01
./.agents/skills/kangentic-pipeline-analysis/scripts/report.sh card 18
```

The helper discovers the project database from the repository path and
Kangentic's `index.db`. It opens SQLite with `-readonly`, never hard-codes a
project UUID, and excludes descriptions and transcript bodies from normal
output.

## Assess efficiency and outcome separately

For efficiency, compare like-for-like cohorts by stage, actual applied agent and
model, effort, and time window. Report at least:

- sessions and cards represented;
- total and median cost when the provider reports cost;
- input, output, cache-creation, and cache-read tokens;
- turns, duration, tool calls, and compactions where recorded;
- the few sessions dominating the total.

Do not treat zero Codex cost as free; it means Kangentic did not record a
provider charge. Do not add session input totals to turn cache fields: they are
overlapping views. State the metric source and denominator.

For outcome quality, inspect the card's pipeline log and committed
the resolved `.kanban/` card artifacts. Count review corrections, replans, Needs input
routes, passed checks, and completion state. The database has no durable task
column-transition history, so it cannot establish those outcomes alone.

## Compare without overclaiming

- Use the same stages and date boundaries for baseline and candidate cohorts.
- Prefer medians and distributions over one aggregate dominated by a huge card.
- Treat profile assignment as current card state; sessions record applied model
  and effort but do not reliably snapshot the profile that selected them.
- Call small samples directional. Model, task size, role, and process changes are
  confounders unless held stable.
- Separate measured facts, inferences, and recommendations.

Recommend the smallest reversible change supported by repeated evidence. A
finding does not authorize editing `kangentic.json`, assigning profiles, moving
cards, killing sessions, or updating the database.

## Deliverable

Lead with the decision the evidence supports. Include the cohort/window, key
numbers, dominant outliers, outcome evidence, caveats, and a concrete next
measurement. Persist only durable conclusions in the pipeline concept document;
do not commit raw databases, transcripts, or potentially sensitive card dumps.
