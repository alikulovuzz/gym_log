# Install our own self-built .rpk on the band

Type: task
Status: open
Blocked by: 01, 02

## Question

Will the band run an `.rpk` that **we** built, rather than one downloaded from bandbbs.cn?

This is a genuinely different question from ticket 01, and it is the one that most often kills projects like this: **signing**. A community `.rpk` may carry a valid signature from a Xiaomi-issued developer certificate, while `aiot build` on our machine produces something unsigned or self-signed. The band may cheerfully install the former and silently reject the latter.

Settle:

- Take the hello-world `.rpk` from ticket 02, push it via the install route proven in ticket 01, and see whether it installs, appears in the band's app list, and launches.
- If it is rejected: what exactly rejects it — the phone-side tool, or the band? What does the error say? Is the blocker a **signature**, a **manifest field** (appid, minimum API level, device whitelist), or a **package format** mismatch?
- If signing is the blocker, find how the community gets around it — do the modded installers strip or bypass signature checks, does the band have a developer/debug mode that permits unsigned packages, or is a Xiaomi certificate genuinely required? (If a certificate is genuinely required for *any* install, that collides with the map's out-of-scope line on Xiaomi's developer process — and the destination must be re-examined rather than quietly expanded.)
- Establish the **iteration loop**: how long does one build → install → run cycle take, and is there any on-device logging or console we can see? A blind edit-and-pray loop makes everything after this ticket several times more expensive, so it is worth finding out now.

## Notes

HITL — needs the band. Blocked because it composes ticket 01's install route with ticket 02's build output; neither alone answers it.

When this ticket closes green, the way is clear to write real code for the band. It is the true "can I do this at all" milestone — 01 proves the *door* opens, this proves it opens for *us*.
