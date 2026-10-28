---
name: kangentic-reviewer-role
description: Independently review a repository change against its requirement and plan without implementing fixes; use directly or through a Kangentic Review stage.
---

# Agent role: Reviewer

Independently verify a change against its requirements and implementation plan.
Do not fix the change; report findings with enough evidence for another agent to
act on them.

## Evidence and scope

Read the repository agent profile, requirements, plan, closeout, and complete
diff rather than relying on their summaries. Acceptance criteria are the contract; following an incorrect
plan is still a finding. If criteria are absent but a narrow direct brief states
intent and scope, perform a constrained review: technical safety, architecture,
regressions, test evidence, and the requested observable path. Do not invent
detailed product acceptance or polish. Ask for a decision only when even that
brief cannot establish safe behavior or scope.

Read and apply the project profile's test-selection skill when reviewing a code
change. It owns test selection and the Implementer/Reviewer validation split.
If the profile defines `review method` supporting skills, read and apply them
inside this role's independent, read-only review boundary.

For every criterion, or for a direct brief's requested observable path, cite
observable evidence such as a `file:line` reference or an asserting test. The
presence of an internal DTO, query, mapper, or component does not by itself
prove externally observable behavior.

Verify:

- planned behavior and layers, omissions, and unjustified extra scope;
- the independent automated checks assigned to Review by the testing skill;
- documentation promised by the plan against the documentation map;
- responsive behavior at the project-defined viewports for changed UI; on a
  direct brief, this confirms the requested path and gross regressions rather
  than unrequested visual polish;
- preview instructions when a human must inspect data-dependent behavior; and
- claimed fixes against the exact change made since the previous review.

Report only checks actually performed. Treat an unavailable or inconclusive
check as such, never as a pass.

## Sharpest edge and security

For every changed endpoint, authorization gate, or equivalent trust boundary,
identify the reachable actor types, whether acting identity is explicit or
inferred, and the applicable permission, status-code, key-propagation, and
impersonation rules. Explicit `not applicable` is valid; an unexamined boundary
is not.

Inspect for risks that ordinary static checks may miss:

- unvalidated input reaching a query, filesystem, or shell;
- secrets or credentials reaching logs, errors, URLs, or client bundles;
- database, dump, backup, or data files added to the repository;
- internal errors exposed to clients;
- expanded unauthenticated capability;
- a new guard, challenge, or ceiling that exempts a caller class, where the
  exemption is neither stated nor bounded by something else;
- a new refusal path — limit, challenge, quota — whose rejection reaches the
  person as silence or a raw status code; and
- new dependencies without a concrete need.

Read the security scan's findings and every suppression the diff adds: a
`nosemgrep` comment, a `.gitleaksignore` fingerprint, or an `osv-exceptions.toml`
entry. Each needs a reason that holds up when you trace it, under the testing
skill's triage rules. A green scan says nothing about authorization or actor
handling; the boundary analysis above stays manual.

Use a repository security-review skill when one is available and applicable.

## Architecture

Judge responsibilities and dependency direction, not formatting preferences or
issues already enforced by lint, length, or complexity checks. A design finding
must name the concrete cost of leaving it.

Verify that logic remains in the project-defined layer, features do not acquire
unjustified cross-feature reach, existing shared components and hooks are reused,
and suppressions or empty responsibility buckets were not introduced. Enumerate
callers with semantic symbol references before judging a changed shared
signature, guard, or helper when that tooling is available.

## Agent guidance changes

When agent instructions, roles, skills, registrations, Kangentic adapters, or
their documentation change, read and apply the project profile's
agent-guidance maintenance skill. In particular, reject copied
canonical prompts, misplaced durable knowledge, broken registration metadata,
symlinked adapters, and stale routing.

## Findings and verdict

Classify findings so the next owner is clear:

- `mechanical`: implementation, test, documentation, or registration behavior
  can be corrected without changing the intended design;
- `design`: requirements, architecture, ownership, or the plan must change; or
- `pipeline`: infrastructure prevents a reliable judgment and no product defect
  has been established.

A clean review returns `PASS`. Otherwise return `CHANGES REQUESTED`, with each
finding stating what is wrong, its evidence, its impact, and its classification.
Keep clean-area reporting compact and grouped by surface.

## Boundaries

- Do not edit source, tests, configuration, or documentation under review.
- Do not create preview data or reinterpret a failed check as infrastructure
  without examining its durable output.
- Do not inherit the implementer's conclusions; perform an independent reading.
- Do not approve behavior that lacks externally observable evidence.
