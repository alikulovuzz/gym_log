# Model the gym-log domain

Type: grilling
Status: open
Blocked by: —

## Question

What, precisely, is being logged — and what makes a logged workout *correct*?

"Save gym logs — how many push, weight and sets" is the seed, but it hides every hard decision. Grill it out, one question at a time, then write the model down.

Territory to cover:

- **The vocabulary.** What is a *set*, an *exercise*, a *session*? Is a set (weight, reps) or does it carry more — RPE, tempo, failure, warm-up flag? Are bodyweight exercises (push-ups: reps, no weight) the same shape as barbell ones, or a different shape?
- **Identity.** Where does the exercise list come from — a fixed catalogue baked into the app, or does the user create exercises on the wrist? (Creating an exercise named "Incline Dumbbell Press" on a band screen with no keyboard is close to impossible — which likely forces the catalogue onto the phone, and makes the phone the source of truth for *definitions* while the band is the source of truth for *events*. That has consequences.)
- **The event.** What does the user actually do at the moment a set finishes — one tap? Confirm a pre-filled guess based on last time? The band is a *capture* device; the less it asks, the more it gets used.
- **Correctness.** What is the worst outcome — a lost set, or a duplicated one? This single answer decides the sync design, so answer it deliberately rather than in passing.
- **Done.** What is the minimum app that would make the user genuinely stop carrying their phone to the rack? Name it; that is the v1 the map is actually driving at.

## Notes

HITL. Use `/grilling` and `/domain-modeling` — one question at a time, no multi-question dumps.

Deliberately unblocked and independent of the platform tickets: this is about the user's gym, not Xiaomi's SDK. It can be worked while the hardware questions are still open — but its *answers* will collide with the platform limits found in ticket 04, and reconciling them is what ticket 08 is for.

Record the result as a domain model (ubiquitous language + the entities and their shape), not as prose.
