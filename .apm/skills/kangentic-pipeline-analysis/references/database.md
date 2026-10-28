# Kangentic database access

Read this reference only when MCP evidence is unavailable or insufficient for a
pipeline assessment.

## Locate the project database

Kangentic keeps a global `index.db` containing `projects(id, name, path, ...)`
and one database per project at `projects/<id>.db`. Typical application-data
directories are:

| Platform | Default |
|---|---|
| macOS | `~/Library/Application Support/kangentic` |
| Linux | `${XDG_CONFIG_HOME:-~/.config}/kangentic` |
| Windows | `%APPDATA%\kangentic` |

Set `KANGENTIC_ANALYSIS_DATA_DIR` when the installation uses another location.
Always resolve the project id through `index.db`; UUIDs are installation-local.
The bundled `scripts/report.sh` performs this discovery from the current
repository path.

## Read safely

- Use `sqlite3 -readonly`. Never update Kangentic tables directly.
- Kangentic uses WAL mode. A report is a point-in-time read of committed rows;
  state may advance immediately after it completes.
- Do not commit a database, WAL file, transcript, or raw card description.
- Default to aggregate fields. Transcript and description bodies may contain
  credentials, private feedback, or pasted external material.
- Inspect `.schema <table>` before a custom query. Kangentic is evolving and
  columns may differ between versions.

The report helper requires `index.db` plus these project tables:
`tasks`, `swimlanes`, `sessions`, `conversation_turn_usage`, and
`session_transcripts`.

## Useful relationships

| Evidence | Relationship or limitation |
|---|---|
| Current card and column | `tasks.swimlane_id → swimlanes.id` |
| Sessions for a card | `sessions.task_id → tasks.id` |
| Isolated role target | `sessions.isolated_swimlane_id → swimlanes.id` |
| Per-turn token composition | `conversation_turn_usage.session_id → sessions.id` |
| Stored transcript size | `session_transcripts.session_id → sessions.id` |
| Current profile selection | `tasks.profile_id`; this is not a historical session snapshot |
| Applied runtime | `sessions.session_type`, `applied_model`, `applied_effort` |
| Workflow outcome | card pipeline log and `.kanban/<task-id>/` artifacts, not the database alone |

Older sessions can lack `isolated_swimlane_id`. The helper then derives a stage
only when the recorded startup prompt names a known role adapter and otherwise
reports `Unattributed`.

## Metric semantics

`sessions.total_input_tokens`, `total_output_tokens`, and `total_cost_usd` are
Kangentic's session-level totals. `conversation_turn_usage` supplies plain
input, output, cache-creation input, and cache-read input by turn. These views
overlap; never sum session input with turn input/cache totals.

Cache-read share is:

```text
cache_read / (plain_input + cache_creation + cache_read)
```

High cache-read share is not automatically waste: cached input is cheaper than
new input. Combine it with total cost, turn count, transcript size, and outcome
quality. Long conversations with rising cache reads and repeated corrections
are stronger evidence than any one field.

Cost fields are provider dependent. A recorded zero means “no charge recorded”,
not “the work consumed no resources”. Compare token and time measures alongside
cost.

## Detailed inspection order

For one card:

1. Run `report.sh card <display-id-or-uuid>` for metadata, sessions, token
   composition, transcript sizes, activity, and artifact inventory.
2. Read the compact pipeline log and `plan.md`, `closeout.md`, and `review.md`.
3. Retrieve a transcript only for a specific unresolved rationale or delivery
   question. Search within it; do not load every transcript by default.
4. Attribute every conclusion to the database, an artifact, or a transcript.

For a before/after assessment, save aggregate report output outside the
repository and record the exact cutoff dates. Use completed cards where possible
and report both efficiency and review outcome so cheaper but less reliable work
does not look like an improvement.
