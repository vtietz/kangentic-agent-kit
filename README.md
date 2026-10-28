# Kangentic Agent Kit

Kangentic Agent Kit is a portable, versioned workflow for moving software work
through refinement, planning, implementation, independent review, preview, and
release. It packages reusable agent roles and workflow skills without embedding
the commands, technologies, or policies of one application repository.

The kit was extracted from MiruList after its agent workflow became useful
beyond that project. Keeping the reusable behavior here gives every consuming
repository the same reviewed workflow while allowing each project to retain its
own commands, quality gates, risk rules, and release policy.

## What is Kangentic?

[Kangentic](https://github.com/Kangentic/kangentic) is an open source agentic
development environment. Its desktop Kanban board starts, monitors, suspends,
and resumes AI coding-agent sessions. Board columns can select different agents,
models, permissions, prompts, and automation, while isolated Git worktrees keep
parallel tasks from changing the same checkout.

This repository is not Kangentic itself and is not required to use the
Kangentic application. It provides an opinionated software-delivery workflow
that works particularly well with a Kangentic board. The portable roles can
also be selected directly in Codex, Claude Code, and GitHub Copilot without a
board.

See the [Kangentic documentation](https://kangentic.com/overview/) for the board
and application, or run `npx kangentic` to start it.

## What the kit provides

The package contains four role boundaries:

- **Refiner:** turns a rough request into an approvable requirement without
  designing the implementation.
- **Planner:** produces an implementation-ready plan grounded in the consuming
  repository.
- **Implementer:** implements and verifies the approved requirement and plan.
- **Reviewer:** independently checks the result and does not repair its own
  findings.

Supporting skills provide card lifecycle and handoff behavior, optional preview
checkpoints, read-only pipeline analysis, release preparation, and initial
repository setup. The `kangentic-kit-development` skill teaches an installed
consumer how to contribute, test, release, and adopt improvements to the kit.
Named-agent projections make the roles discoverable in Codex, Claude Code, and
GitHub Copilot.

The separation is deliberate. A role defines responsibility, required evidence,
and where an agent must stop. The consuming repository defines how to build and
test its application, what risks matter, and how work moves through its board.

## Why use a separate package?

Copying role prompts between repositories creates several sources of truth.
Fixes drift, vendor-specific agent files diverge, and application details leak
into otherwise reusable instructions. This kit instead provides:

- one canonical source for reusable roles and workflow procedures;
- explicit versions and reproducible installs;
- generated registrations for supported agent tools;
- a clear boundary between portable workflow and project policy;
- upgrades that can be reviewed as ordinary repository changes; and
- the ability to test kit changes against a real consuming repository before
  publishing them.

## Packaging and portability

The package uses [Microsoft APM](https://microsoft.github.io/apm/), the Agent
Package Manager, rather than a Kangentic-specific installer. Its canonical
sources live under `.apm/`. APM deploys the selected skills and named-agent
projections, records exact content in `apm.lock.yaml`, and can audit installed
files for drift.

Skills follow the Agent Skills specification. The
`scripts/build-agent-plugin.sh` command also produces a portable Agent Plugins
subset for compatible tools. Kangentic board configuration remains a
repository-owned integration layer because board columns, hooks, and release
rules differ by project.

## Install

Install the released package in the repository that will use it:

```bash
apm install vtietz/kangentic-agent-kit#v0.2.0
```

Commit `apm.yml`, `apm.lock.yaml`, and APM's generated target files. CI should
restore and audit the exact locked package:

```bash
apm install --frozen
apm audit --ci
```

After the first install, ask an agent to use `kangentic-setup`. The setup skill
inspects the repository and creates or adapts its project profile, board
overlay, role adapters, hooks, and board configuration. It treats bundled
examples as starting points, never as facts about the consuming project.

Installing the kit does not install the Kangentic desktop application. Install
or run Kangentic separately when a board-driven workflow is wanted.

## Package and project ownership

APM owns installed `kangentic-*` skills, named-agent projections, version pins,
integrity checks, updates, and removal. Do not edit those generated copies in a
consuming repository.

The consuming repository owns its project facts and integration, including:

- `.agents/project.md` for commands, checks, risks, and project skills;
- `.kanban/project.md` for board-specific policy;
- `.kanban/kangentic-config.json` and `kangentic.json` for board configuration;
- `.kanban/roles/` for project-specific board adapters; and
- `scripts/project-pipeline/` for project hooks.

The reusable package contains no application framework, language, test runner,
port, credential, product, or release-policy assumptions.

## Updating a consuming repository

Consumers stay pinned to the package version and content hashes recorded in
`apm.lock.yaml`. To adopt a new release, change the package reference or run the
appropriate APM update command, review the generated changes, run the consuming
project's validation, and commit the manifest, lockfile, and projections
together.

For local kit development, clone this repository next to the consuming project
and temporarily use the local package source. Test the workflow in the real
project, commit and tag the kit change here, then return the consumer to the new
released version. Do not commit a machine-specific local path in the consuming
repository.

## Develop and validate

Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing or releasing the kit.
Installed consumers can invoke `kangentic-kit-development` for the same
maintenance workflow in agent-readable form.

```bash
./scripts/validate.sh
./scripts/test-install.sh
./scripts/build-agent-plugin.sh
```

Release with a SemVer tag. Consumers remain pinned until they explicitly adopt
the new version.

## Relationship to MiruList

[MiruList](https://github.com/vtietz/movie-voting-app) is the first consuming
project and the environment in which this workflow was developed. MiruList is
not a runtime dependency. Project-specific behavior stays in the MiruList
repository, while generally useful improvements are contributed here and
released for any consumer.

## License

Kangentic Agent Kit is available under the [MIT License](LICENSE). Kangentic is
a separate project with its own license and maintainers.
