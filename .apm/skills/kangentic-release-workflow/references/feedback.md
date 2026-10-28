# Questions and release feedback

For a question, start with the card, Review, and the one relevant closeout
section. Read the relevant plan section only when those do not record the
rationale. If rationale is still absent, consult the originating role transcript
with `kangentic_get_transcript`.
Attribute the answer to its artifact/transcript or state “not recorded”; do not
present inference as recorded fact. A question alone does not move the card.

Before routing requested changes, quote the human verbatim under card `## Human
feedback (<date>)`. Attach a screenshot and useful DOM/box evidence for a visual
complaint. Human feedback has no automated round cap.

| Feedback | Route |
|---|---|
| Wording, icon, spacing, color, status, validator, or local correction | Implementation |
| Different structure, redesign, or shape | Planning |
| Not what was requested | Planning; requirement must change |
| Shelve or not now | Refinement |

Stop preview before routing unless the human still uses it. Apply the profile's
destination labels and persist `role=release-steward; outcome=feedback` through
the card-lifecycle skill. The Release Steward never fixes the product itself.
