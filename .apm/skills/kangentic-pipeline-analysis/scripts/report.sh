#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  report.sh summary [SINCE] [PROJECT_PATH]
  report.sh card CARD_ID_OR_NUMBER [PROJECT_PATH]

Environment:
  KANGENTIC_ANALYSIS_DATA_DIR  Override Kangentic's application-data directory.

Examples:
  report.sh summary
  report.sh summary 2026-08-01 /path/to/project
  report.sh card 18 /path/to/project
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

heading() {
  printf '\n## %s\n\n' "$1"
}

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

resolve_data_dir() {
  if [[ -n "${KANGENTIC_ANALYSIS_DATA_DIR:-}" ]]; then
    printf '%s\n' "$KANGENTIC_ANALYSIS_DATA_DIR"
    return
  fi

  case "$(uname -s)" in
    Darwin) printf '%s\n' "$HOME/Library/Application Support/kangentic" ;;
    Linux) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/kangentic" ;;
    *) fail 'set KANGENTIC_ANALYSIS_DATA_DIR for this platform' ;;
  esac
}

resolve_project_db() {
  local requested_path="$1"
  local data_dir index_db project_path escaped_path project_ids project_id

  data_dir="$(resolve_data_dir)"
  index_db="$data_dir/index.db"
  [[ -f "$index_db" ]] || fail "Kangentic index not found: $index_db"
  [[ -d "$requested_path" ]] || fail "project path not found: $requested_path"
  project_path="$(cd "$requested_path" && pwd -P)"
  escaped_path="$(sql_escape "$project_path")"
  project_ids="$(sqlite3 -readonly "$index_db" \
    "SELECT id FROM projects WHERE path = '$escaped_path' ORDER BY last_opened DESC;")"
  [[ -n "$project_ids" ]] || fail "project is not registered in Kangentic: $project_path"
  [[ "$(printf '%s\n' "$project_ids" | wc -l | tr -d ' ')" == "1" ]] || \
    fail "multiple Kangentic projects use path: $project_path"
  project_id="$project_ids"
  PROJECT_ROOT="$project_path"
  PROJECT_DB="$data_dir/projects/$project_id.db"
  [[ -f "$PROJECT_DB" ]] || fail "project database not found: $PROJECT_DB"
}

require_schema() {
  local table
  for table in tasks swimlanes sessions conversation_turn_usage session_transcripts; do
    [[ "$(sqlite3 -readonly "$PROJECT_DB" \
      "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='$table';")" == "1" ]] || \
      fail "unsupported Kangentic schema: missing table $table"
  done
}

stage_case="CASE
  WHEN sl.name IS NOT NULL THEN sl.name
  WHEN s.prompt LIKE '%.kanban/roles/refiner.md%' THEN 'Refinement'
  WHEN s.prompt LIKE '%.kanban/roles/planner.md%' THEN 'Planning'
  WHEN s.prompt LIKE '%.kanban/roles/implementer.md%' THEN 'Implementation'
  WHEN s.prompt LIKE '%.kanban/roles/reviewer.md%' THEN 'Review'
  WHEN s.prompt LIKE '%.kanban/roles/release-steward.md%'
    OR s.prompt LIKE '%.kanban/roles/steward.md%' THEN 'Release Gate'
  ELSE 'Unattributed'
END"

summary_report() {
  local since="$1" escaped_since
  [[ "$since" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]] || \
    fail "SINCE must begin with YYYY-MM-DD: $since"
  escaped_since="$(sql_escape "$since")"

  printf 'Project: %s\nDatabase: %s\nSince: %s\n' "$PROJECT_ROOT" "$PROJECT_DB" "$since"

  heading 'Current board inventory'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
SELECT sl.name AS current_column,
       count(t.id) AS cards,
       sum(CASE WHEN t.id IS NOT NULL AND t.archived_at IS NULL THEN 1 ELSE 0 END) AS active,
       sum(CASE WHEN t.id IS NOT NULL AND t.profile_id IS NOT NULL THEN 1 ELSE 0 END) AS profiled
FROM swimlanes sl
LEFT JOIN tasks t ON t.swimlane_id = sl.id
WHERE sl.is_archived = 0
GROUP BY sl.id, sl.name, sl.position
ORDER BY sl.position;
SQL

  heading 'Sessions by stage and applied runtime'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
WITH enriched AS (
  SELECT s.*,
         $stage_case AS stage,
         s.session_type AS runtime_agent,
         coalesce(s.applied_model, s.model_id, '(unknown)') AS runtime_model,
         coalesce(s.applied_effort, '(unknown)') AS runtime_effort,
         coalesce(s.total_cost_usd, 0) AS recorded_cost
  FROM sessions s
  LEFT JOIN swimlanes sl ON sl.id = s.isolated_swimlane_id
  WHERE s.started_at >= '$escaped_since'
), ranked AS (
  SELECT enriched.*,
         row_number() OVER (
           PARTITION BY stage, runtime_agent, runtime_model, runtime_effort
           ORDER BY recorded_cost
         ) AS cost_rank,
         count(*) OVER (
           PARTITION BY stage, runtime_agent, runtime_model, runtime_effort
         ) AS cohort_size
  FROM enriched
)
SELECT stage,
       runtime_agent AS agent,
       runtime_model AS model,
       runtime_effort AS effort,
       count(*) AS sessions,
       count(DISTINCT task_id) AS cards,
       round(sum(recorded_cost), 2) AS recorded_cost_usd,
       round(avg(CASE
         WHEN cost_rank IN ((cohort_size + 1) / 2, (cohort_size + 2) / 2)
         THEN recorded_cost
       END), 2) AS median_cost_usd,
       sum(coalesce(total_input_tokens, 0)) AS reported_input,
       sum(coalesce(total_output_tokens, 0)) AS reported_output,
       round(sum(coalesce(total_duration_ms, 0)) / 3600000.0, 2) AS duration_hours,
       sum(coalesce(tool_call_count, 0)) AS tool_calls,
       sum(coalesce(compaction_count, 0)) AS compactions
FROM ranked
GROUP BY stage, runtime_agent, runtime_model, runtime_effort
ORDER BY recorded_cost_usd DESC, reported_input DESC;
SQL

  heading 'Turn token composition by stage'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
WITH enriched AS (
  SELECT s.id, $stage_case AS stage
  FROM sessions s
  LEFT JOIN swimlanes sl ON sl.id = s.isolated_swimlane_id
  WHERE s.started_at >= '$escaped_since'
), totals AS (
  SELECT e.stage,
         count(*) AS turns,
         count(DISTINCT u.session_id) AS sessions,
         sum(u.input_tokens) AS plain_input,
         sum(u.cache_creation_input_tokens) AS cache_creation,
         sum(u.cache_read_input_tokens) AS cache_read,
         sum(u.output_tokens) AS output
  FROM conversation_turn_usage u
  JOIN enriched e ON e.id = u.session_id
  GROUP BY e.stage
)
SELECT *,
       round(100.0 * cache_read /
         nullif(plain_input + cache_creation + cache_read, 0), 1) AS cache_read_pct
FROM totals
ORDER BY cache_read DESC;
SQL

  heading 'Largest sessions'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
WITH turn_totals AS (
  SELECT session_id,
         count(*) AS turns,
         sum(cache_creation_input_tokens) AS cache_creation,
         sum(cache_read_input_tokens) AS cache_read
  FROM conversation_turn_usage
  GROUP BY session_id
), enriched AS (
  SELECT s.*, t.display_id, t.title, $stage_case AS stage
  FROM sessions s
  JOIN tasks t ON t.id = s.task_id
  LEFT JOIN swimlanes sl ON sl.id = s.isolated_swimlane_id
  WHERE s.started_at >= '$escaped_since'
)
SELECT display_id AS card,
       stage,
       substr(title, 1, 42) AS title,
       coalesce(applied_model, model_id, '(unknown)') AS model,
       round(coalesce(total_cost_usd, 0), 2) AS recorded_cost_usd,
       coalesce(tt.turns, 0) AS turns,
       coalesce(tt.cache_read, 0) AS cache_read,
       coalesce(st.size_bytes, 0) AS transcript_bytes,
       started_at
FROM enriched e
LEFT JOIN turn_totals tt ON tt.session_id = e.id
LEFT JOIN session_transcripts st ON st.session_id = e.id
ORDER BY recorded_cost_usd DESC, cache_read DESC
LIMIT 15;
SQL
}

card_report() {
  local selector="$1" escaped_selector card_ids card_id worktree_path
  local artifact_root card_dir artifact match matches
  [[ "$selector" =~ ^[[:alnum:]-]+$ ]] || fail 'card selector may contain only letters, numbers, and hyphens'
  escaped_selector="$(sql_escape "$selector")"
  card_ids="$(sqlite3 -readonly "$PROJECT_DB" \
    "SELECT id FROM tasks WHERE CAST(display_id AS TEXT) = '$escaped_selector' OR id = '$escaped_selector' OR id LIKE '$escaped_selector%' ORDER BY updated_at DESC;")"
  [[ -n "$card_ids" ]] || fail "card not found: $selector"
  [[ "$(printf '%s\n' "$card_ids" | wc -l | tr -d ' ')" == "1" ]] || fail "card selector is ambiguous: $selector"
  card_id="$card_ids"

  printf 'Project: %s\nDatabase: %s\nCard id: %s\n' "$PROJECT_ROOT" "$PROJECT_DB" "$card_id"

  heading 'Card'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
SELECT t.display_id,
       t.id,
       t.title,
       sl.name AS current_column,
       t.run_mode,
       coalesce(t.profile_id, '(Default)') AS current_profile_id,
       length(CAST(t.description AS BLOB)) AS description_bytes,
       t.labels,
       t.branch_name,
       t.head_sha,
       t.created_at,
       t.updated_at,
       t.archived_at
FROM tasks t
JOIN swimlanes sl ON sl.id = t.swimlane_id
WHERE t.id = '$card_id';
SQL

  heading 'Sessions'
  sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
WITH enriched AS (
  SELECT s.*, $stage_case AS stage
  FROM sessions s
  LEFT JOIN swimlanes sl ON sl.id = s.isolated_swimlane_id
  WHERE s.task_id = '$card_id'
), turn_totals AS (
  SELECT session_id,
         count(*) AS turns,
         sum(input_tokens) AS plain_input,
         sum(cache_creation_input_tokens) AS cache_creation,
         sum(cache_read_input_tokens) AS cache_read
  FROM conversation_turn_usage
  GROUP BY session_id
)
SELECT e.id AS session_id,
       e.stage,
       e.session_type AS agent,
       coalesce(e.applied_model, e.model_id, '(unknown)') AS model,
       coalesce(e.applied_effort, '(unknown)') AS effort,
       e.status,
       round(coalesce(e.total_cost_usd, 0), 2) AS recorded_cost_usd,
       coalesce(tt.turns, 0) AS turns,
       coalesce(tt.plain_input, 0) AS plain_input,
       coalesce(tt.cache_creation, 0) AS cache_creation,
       coalesce(tt.cache_read, 0) AS cache_read,
       coalesce(e.total_output_tokens, 0) AS reported_output,
       coalesce(e.tool_call_count, 0) AS tool_calls,
       coalesce(e.compaction_count, 0) AS compactions,
       coalesce(st.size_bytes, 0) AS transcript_bytes,
       e.started_at,
       e.exited_at
FROM enriched e
LEFT JOIN turn_totals tt ON tt.session_id = e.id
LEFT JOIN session_transcripts st ON st.session_id = e.id
ORDER BY e.started_at;
SQL

  if [[ "$(sqlite3 -readonly "$PROJECT_DB" \
    "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='session_activity_intervals';")" == "1" ]]; then
    heading 'Recorded activity'
    sqlite3 -readonly -header -column "$PROJECT_DB" <<SQL
SELECT state,
       disposition,
       count(*) AS intervals,
       round(sum(coalesce(duration_ms, 0)) / 60000.0, 1) AS minutes
FROM session_activity_intervals
WHERE task_id = '$card_id'
GROUP BY state, disposition
ORDER BY minutes DESC;
SQL
  fi

  heading 'Committed card artifacts'
  worktree_path="$(sqlite3 -readonly "$PROJECT_DB" \
    "SELECT coalesce(worktree_path, '') FROM tasks WHERE id = '$card_id';")"
  artifact_root="$PROJECT_ROOT"
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    artifact_root="$worktree_path"
  fi

  card_dir=""
  matches=0
  while IFS= read -r match; do
    artifact_card_id="$("$PROJECT_ROOT/.agents/skills/kangentic-card-lifecycle/scripts/card-id.sh" "$match" 2>/dev/null || true)"
    if [[ "$artifact_card_id" == "$card_id" ]]; then
      card_dir="$match"
      matches=$((matches + 1))
    fi
  done < <(find "$artifact_root/.kanban" -mindepth 1 -maxdepth 1 -type d ! -name roles -print 2>/dev/null)

  if [[ "$matches" -ne 1 ]]; then
    printf 'Expected one artifact directory under %s/.kanban; found %s.\n' \
      "$artifact_root" "$matches"
    return
  fi
  while IFS= read -r artifact; do
    printf '%8s  %s\n' "$(wc -c < "$artifact" | tr -d ' ')" "${artifact#$artifact_root/}"
  done < <(find "$card_dir" -maxdepth 1 -type f -print | sort)
}

command -v sqlite3 >/dev/null 2>&1 || fail 'sqlite3 is required'

command_name="${1:-summary}"
case "$command_name" in
  summary)
    since="${2:-1970-01-01}"
    project_arg="${3:-.}"
    resolve_project_db "$project_arg"
    require_schema
    summary_report "$since"
    ;;
  card)
    [[ $# -ge 2 ]] || { usage >&2; exit 2; }
    selector="$2"
    project_arg="${3:-.}"
    resolve_project_db "$project_arg"
    require_schema
    card_report "$selector"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    fail "unknown command: $command_name"
    ;;
esac
