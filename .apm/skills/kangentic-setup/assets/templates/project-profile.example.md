# Repository agent profile

Read this profile before a portable role or Kangentic board profile. Replace
every placeholder with a repository-owned source, skill, command, hook, or an
explicit `not applicable`.

## Sources and policies

| Slot | Repository owner |
|---|---|
| agent guide | `<path>` |
| product principles | `<path or not applicable>` |
| documentation map | `<path>` |
| architecture | `<path>` |
| proposed requirements | `<path>` |
| decisions | `<path>` |
| changelog | `<path or not applicable>` |
| authorization and actors | `<path or not applicable>` |

Requirement archival policy: `<policy>`.

## Skills

| Slot | Skill |
|---|---|
| command execution | `<skill path>` |
| test selection | `<skill path>` |
| applicable development skills | `<skill paths>` |
| agent-guidance maintenance | `<skill path>` |
| Kangentic kit development | `.agents/skills/kangentic-kit-development/SKILL.md` |
| pull-request workflow | `<skill path or not applicable>` |

## Commands and hooks

| Slot | Command |
|---|---|
| bootstrap | `<command>` |
| preview / cleanup | `<command or not applicable>` |
| selected browser validation | `<command or not applicable>` |
| repository check | `<command>` |
| security scan | `<command or not applicable>` |
| focused diagnostics | `<command>` |
| unit tests | `<command>` |
| integration/API tests | `<command or not applicable>` |
| browser tests | `<command or not applicable>` |
| schema migration | `<command or not applicable>` |
| pull request | `<command or not applicable>` |

## Risk and UI gates

- Sharpest edge and relevant actors: `<risk contract>`.
- Changed user-facing UI: `<responsive or visual gate, or not applicable>`.
- Static-analysis and security suppression policy: `<policy>`.
- Preview data and actor: `<policy or not applicable>`.
- Comparison worktree and environment isolation: `<policy>`.
