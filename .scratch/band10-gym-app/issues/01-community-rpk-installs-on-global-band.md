# Prove a community .rpk installs and runs on the Global Band 10

Type: task
Status: open
Blocked by: —

## Question

Can *any* third-party `.rpk` be installed onto this specific band — Xiaomi Smart Band 10, **Global** firmware, Android-paired — and actually launch?

This is the kill-switch ticket. If the answer is no, the destination is unreachable by this route and the whole map must be redrawn. Nothing downstream is worth building until this is settled, so it is deliberately the cheapest possible test: use **someone else's already-working app**, so that a failure indicts the *install route* and not our code.

Settle, concretely:

- Which tool actually detects this band — **Notify for Xiaomi** (*update section → third-party app (RPK)*) or **@m0tral's modded Mi Fitness**? The r/miband thread has people failing here with "it does not detect MI band 10 at all", so expect friction and record precisely what worked.
- Whether the original Mi Fitness must be uninstalled first, and whether the band must be unpaired/repaired (note: repairing may factory-reset the band).
- What permissions / developer toggles the phone or band needs.
- Record the band's exact **firmware version and model number** — every later result is only meaningful relative to it.

Fetch a known-good app from **bandbbs.cn** to test with.

## Notes

This is HITL: it needs the physical band, the phone in hand, and app installs the agent cannot perform. The agent's job is to produce a precise, ordered checklist, then interpret what happens — including reading error messages and searching for others who hit the same one.

The answer must record the **working install procedure** step by step. Every later hardware ticket depends on being able to repeat it.
