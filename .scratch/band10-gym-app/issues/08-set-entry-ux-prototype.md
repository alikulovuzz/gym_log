# Design set-entry UX for a band-sized screen

Type: prototype
Status: open
Blocked by: 04, 05

## Question

How does a sweating human, mid-workout, tell a band that they just did 85 kg × 5 — in under three seconds, one-handed?

This is the question the product lives or dies on. A gym app that takes twenty seconds and four screens to log a set will not be used; the user will go back to their phone. Everything else in this map is plumbing in service of this interaction.

Make something concrete and react to it rather than arguing in the abstract:

- Sketch two or three genuinely different set-entry models — e.g. *confirm-the-guess* (band pre-fills last session's weight and reps, one tap accepts), *steppers* (±2.5 kg, ±1 rep), *dial/scroll picker*. The best design likely does almost no asking.
- Build them as a throwaway prototype at the band's **real** resolution (from ticket 04) — mocked in the browser is fine, and far faster than the band's build-install loop.
- Test them against the domain model from ticket 05: does the design still work for bodyweight push-ups (no weight), for a drop set, for the first-ever time an exercise is done and there is nothing to pre-fill?
- Respect the platform limits from ticket 04 — most importantly, if the app cannot survive the screen turning off between sets, the design must be resumable, and that constraint has to shape the UI rather than be patched on afterwards.

## Notes

HITL. Use `/prototype` (UI). Link the prototype as an asset.

Blocked by both 04 (what the screen and input can do) and 05 (what a set even is). Designing before either is known would produce a beautiful mock of something the band cannot render and the user does not want.
