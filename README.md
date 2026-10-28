# Kangentic Agent Kit

Portable Refiner, Planner, Implementer, and Reviewer roles plus Kangentic card
lifecycle, preview, analysis, and release workflows.

The package uses Microsoft APM's canonical `.apm/` source layout. Skills follow
the Agent Skills specification. `scripts/build-agent-plugin.sh` produces the
portable Agent Plugins subset while APM projects consume the source package.

## Install

Add the package to a repository:

```bash
apm install vtietz/kangentic-agent-kit#v0.1.0
```

Commit `apm.yml`, `apm.lock.yaml`, and APM's generated target files. CI should
restore the exact locked package with:

```bash
apm install --frozen
apm audit --ci
```

After the first install, ask the agent to use `kangentic-setup`. It creates or
adapts the repository-owned project profile, board overlay, adapters, hooks, and
board configuration. Setup never treats the included examples as repository
truth.

## Ownership

APM owns installed skills, named-agent projections, version pins, integrity,
updates, and removal. The consuming repository owns `.agents/project.md`,
`.kanban/project.md`, `.kanban/kangentic-config.json`, `kangentic.json`, and its
`scripts/project-pipeline/` implementations.

The reusable package contains no application framework, language, test runner,
port, credential, product, or release-policy assumptions.

## Develop

```bash
./scripts/validate.sh
./scripts/test-install.sh
./scripts/build-agent-plugin.sh
```

Release with a SemVer tag. Consumers remain pinned by `apm.lock.yaml` until
they explicitly run `apm update`.
