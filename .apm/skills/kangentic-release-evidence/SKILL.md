---
name: kangentic-release-evidence
description: Select, prepare, and verify compact human evidence for a Kangentic Release Gate while keeping the reviewed live application available.
---

# Kangentic release evidence

Read the repository profile's preview and release-evidence hooks, Review's
`## Release brief`, and closeout `## Release evidence`. This skill prepares the
human-facing evidence layer only. It does not review, approve, publish, or land
the change.

## Choose the smallest useful mode

- `live`: interaction is the evidence; open the reviewed application state.
- `screenshot`: one static visual state communicates the result.
- `video`: timing, animation, navigation, state transitions, or a short
  multi-step flow is materially easier to judge in motion.
- `text`: there is no useful visual surface.

Do not create video merely because capture is available. Keep clips focused on
one expected result, normally 5 to 15 seconds, and exclude setup, loading,
credentials, unrelated browser chrome, and idle time.

## Prepare the presentation

Use the project profile's exact capture and presentation hooks. A presentation
page may show the result, the fewest useful actions, the expected outcome, and
one verified screenshot or muted looping clip. It must also provide a prominent
path into the reviewed live application whenever interaction remains useful.
Browser history is an acceptable path back to the evidence page.

Treat the presentation as disposable preview output. Do not commit generated
media, embed secrets, copy card history, or make the page an acceptance
artifact. Escape human-provided text, constrain local asset types, and reject
unsafe destinations rather than interpolating unchecked HTML or URLs.

## Verify and hand back

Open the exact generated URL in the board browser pane. Verify that its text is
readable, the asset loads and loops when applicable, and the live-app control
opens the declared reviewed destination. For `live`, open the app directly. For
`text`, present the compact result without manufacturing a visual.

Return the presentation URL, live destination, mode, asset output when any, and
one expected result to the release workflow. Missing capture, broken playback,
an unsafe or unreachable destination, or a page that cannot enter the live app
is a preview-setup gap, not release-ready evidence.
