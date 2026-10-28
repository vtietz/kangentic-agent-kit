#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
mode="${1:-write}"
[[ "$mode" == "write" || "$mode" == "--check" ]] || {
  echo "usage: $0 [--check]" >&2
  exit 2
}

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

jq -s '
  .[0] as $raw_template | .[1] as $project | .[2] as $installed |
  ($raw_template | walk(
    if type == "string" then
      reduce ($project.tokens | to_entries[]) as $token (.;
        split("${" + $token.key + "}") | join($token.value)
      )
    else . end
  )) as $template |
  ($template.columns | map(
    . as $column |
    ([ $installed.columns[] | select(.name == $column.name) | .id ][0]
      // error("installed config has no ID for column " + $column.name)) as $id |
    ($column + {id: $id} | del(.key))
  )) as $columns |
  ($template.profiles | map(
    .columns as $named |
    .columns = reduce ($named | to_entries[]) as $entry ({};
      ([ $columns[] | select(.name == $entry.key) | .id ][0]
        // error("profile references unknown column " + $entry.key)) as $id |
      . + {($id): $entry.value}
    )
  )) as $profiles |
  ($template + {columns: $columns, profiles: $profiles})
  + (if $installed._modifiedBy then {_modifiedBy: $installed._modifiedBy} else {} end)
' kangentic.template.json .kanban/kangentic-config.json kangentic.json >"$tmp_file"

if [[ "$mode" == "--check" ]]; then
  if ! diff -u <(jq -S . kangentic.json) <(jq -S . "$tmp_file"); then
    echo "kangentic.json has drifted from kangentic.template.json" >&2
    exit 1
  fi
else
  cp "$tmp_file" kangentic.json
fi
