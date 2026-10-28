---
name: kangentic-setup
description: Install, adapt, validate, or update the Kangentic board integration in a repository after the portable kit has been installed through APM.
---

# Kangentic repository setup

Adapt the installed kit to the current repository. Treat files under `assets/`
as templates, not as authority over existing repository decisions.

## Establish the project contract

Inspect the repository's agent guide, documentation map, build and test command
surface, risk boundaries, UI validation, preview mechanism, base branch, and
release policy. Create or update:

- `.agents/project.md` for repository sources, project-prefixed skills,
  commands, hooks, risk, UI gates, and requirement policy;
- `.kanban/project.md` for card artifacts, labels, waiting, routes, and release
  authority; and
- `.kanban/kangentic-config.json` for local agent, model, and prompt-path tokens.

Add a short route to the repository's agent guide or project profile: changes
to reusable Kangentic roles, skills, packaging, or releases use the installed
`kangentic-kit-development` skill. Do not copy that skill's procedure into the
route.

Record optional supporting skills in the project profile by semantic capability:
refinement discovery, planning method, implementation method, debugging method,
and review method. Map only skills the repository has deliberately selected.
Do not infer a mapping merely because a similarly named skill is installed; use
`not applicable` when no method has been chosen. Verify every configured skill
path exists.

Do not copy example-project commands, actors, ports, or product rules. Use `not
applicable` for slots the repository genuinely lacks.

## Install board adapters

Adapt `assets/board-roles/` into `.kanban/roles/`. Preserve their split: the
portable role skills own engineering behavior; adapters own only Kangentic card
persistence, approval, and routing. Install `assets/templates/kangentic.template.json`
at the repository root and adapt its column set deliberately.

Keep project hooks under `scripts/project-pipeline/`. Never overwrite an
existing project profile, hook, board adapter, or installed configuration
without first comparing it and preserving its repository-owned decisions.

## Validate

Confirm every profile slot is concrete, all referenced paths exist, shell and
JSON metadata parse, the installed board retains its column IDs, external writes
still require explicit authority, and a disposable card can traverse a return
path. Report files created, files intentionally preserved, and any integration
decision that still needs a human.
