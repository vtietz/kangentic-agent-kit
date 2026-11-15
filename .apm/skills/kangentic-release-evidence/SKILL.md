---
name: kangentic-release-evidence
description: Select, prepare, and verify compact human evidence for a Kangentic Release Gate while keeping the reviewed live application available.
---

# Kangentic release evidence

Read the repository profile's preview and release-evidence hooks, Review's
`## Release brief`, and closeout `## Release evidence`. Prepare evidence only;
do not review, approve, publish, or land.

## Choose the smallest useful mode

- `live`: interaction matters.
- `screenshot`: one static state explains the result.
- `video`: timing, navigation, state change, or a short flow is clearer in motion.
- `text`: no useful visual surface exists.

Video is optional. Keep it to one expected result, normally 5 to 15 seconds;
exclude setup, loading, credentials, unrelated chrome, and idle time.

## Prepare the presentation

Run the profile's exact hooks. The disposable page contains Result, Try,
Expected, one verified screenshot or muted looping clip, and **Open live app**
when interaction helps. `live` may open the app directly. Do not commit output,
embed secrets, copy card history, or make the page an acceptance artifact. The
project hook must escape text, constrain asset types, and reject unsafe URLs.

## Verify and hand back

Open the exact result in the board pane. Verify readable text, asset playback,
and the reviewed live destination. Return mode, presentation URL, live URL,
asset when any, and expected result. Missing or unsafe output is a preview-setup
gap.
