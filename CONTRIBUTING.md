# Contributing to Kangentic Agent Kit

Kangentic Agent Kit separates reusable delivery behavior from the facts and
automation of any one consuming repository. Contributions should preserve that
boundary.

## Classify the change

Change this repository when the behavior should be useful to more than one
consumer:

- role responsibility, evidence, output, or stopping boundaries;
- portable workflow procedures;
- named-agent projections;
- setup templates that every consumer adapts; or
- package validation, installation, and release mechanics.

Keep application commands, frameworks, ports, actors, credentials, product
rules, board column IDs, and release authority in the consuming repository.
Installed APM projections are generated copies, not an editing surface.

## Develop locally

Clone this repository next to a consuming repository. Make the canonical change
under `.apm/`, then temporarily point the consumer's APM dependency at the local
checkout. A local manifest entry has this shape:

```yaml
dependencies:
  apm:
    - path: ../kangentic-agent-kit
```

Install the local package and test the behavior in the consumer. Preserve any
consumer-owned files and do not commit the machine-specific path or the
temporary lockfile resolution.

## Validate

Run all package checks before publishing:

```bash
./scripts/validate.sh
./scripts/test-portability.sh
./scripts/test-install.sh
rm -rf build/agent-plugin
./scripts/build-agent-plugin.sh
jq empty build/agent-plugin/plugin.json
```

The generated `build/` directory is ignored. The fixture test installs the
package into a disposable repository, verifies native projections, performs a
frozen reinstall, and audits installed content.

## Release

Use semantic versioning. A new role or skill is normally a minor release, a
backward-compatible correction is normally a patch, and an incompatible
workflow or ownership change requires a major release.

1. Update the version in `apm.yml`, `scripts/build-agent-plugin.sh`, and README
   installation examples.
2. Run the full validation above.
3. Commit and push the change.
4. Tag the validated commit and publish the release.
5. Wait for package CI to pass.

Do not move or replace an existing release tag. Consumers rely on version pins
and content hashes being immutable.

## Upgrade a consumer

Return the consumer's dependency to the released Git reference, install the
new version, and audit it. Review the manifest, lockfile, installed skills, and
native projections before committing them together. Then run the consumer's own
required validation.

Project-owned profiles, board adapters, hooks, and configuration are not package
projections. Update them only when the release intentionally changes their
contract, and preserve local decisions while adapting them.

## Pull requests

Describe the reusable problem, the ownership boundary, the validation run, and
the consuming repository used for integration testing. Do not include private
repository data, credentials, generated build output, or unrelated consumer
changes.
