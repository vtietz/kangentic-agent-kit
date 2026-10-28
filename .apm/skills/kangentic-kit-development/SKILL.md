---
name: kangentic-kit-development
description: Contribute, test, release, or adopt changes to Kangentic Agent Kit while keeping reusable package behavior separate from consuming-repository policy.
---

# Develop Kangentic Agent Kit

Use this procedure when a requested change may belong in the reusable kit or
when a consuming repository needs to test or adopt a kit release. This skill
does not grant permission to push, tag, publish, or modify another repository.

## Establish ownership

Classify the change before editing:

- Put reusable roles, workflow skills, agent projections, setup templates, and
  package mechanics in `vtietz/kangentic-agent-kit`.
- Keep project commands, frameworks, ports, actors, credentials, risk policy,
  board identity, hooks, and release authority in the consuming repository.
- Treat APM-installed `kangentic-*` skills and native agent files as generated
  projections. Change their canonical `.apm/` sources in the kit.

If the boundary is unclear, prefer a project-local experiment. Promote it into
the kit only after the reusable contract is understood.

## Work against a consumer

Locate or clone the kit beside the consumer. Inspect the kit's
`CONTRIBUTING.md` completely when working in its checkout. Temporarily point the
consumer's APM dependency at that local path, install it, and exercise the
changed behavior using the consumer's own validation policy.

Do not commit a machine-specific dependency path or temporary local lockfile
resolution. Do not overwrite consumer-owned project profiles, board adapters,
configuration, or hooks while testing package projections.

## Verify the package

Run the kit's validation, fixture installation, and plugin build commands from
`CONTRIBUTING.md`. Check the diff for project-specific terms, duplicated role
bodies, stale registrations, malformed metadata, and generated output.

## Publish and adopt

Publishing is a separate external mutation and requires the user's authority.
When authorized, select the semantic version from compatibility impact, update
all version sources, validate, commit, push, tag, and publish an immutable
release. Do not reuse or move an existing tag.

Upgrade the consumer only after the release exists. Restore its dependency to
the released Git reference, install and audit the package, review all generated
changes, run the consumer's validation, and commit the manifest, lockfile, and
projections together. Report kit and consumer commits separately.
