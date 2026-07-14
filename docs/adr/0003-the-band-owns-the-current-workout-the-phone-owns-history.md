# The band owns the current workout; the phone owns everything older

Sets are editable on the wrist — you will fat-finger reps with chalk on your hands — but only **within the current workout**. Older sets are corrected on the phone. An edit re-sends the same `SetId` with a higher `Revision`; the phone keeps the highest Revision it has seen.

## Considered Options

**Append-only, no edits at all** was the clean option, with corrections deferred entirely to the phone. Rejected: mis-taps happen mid-workout and you want them gone while you still remember the true number.

**Editable forever** — reach back to any set ever logged — was rejected for what it costs on a 1.7" screen. To edit a set you must first *find* it, so unbounded editing means unbounded band-side history, date navigation on a watch, and a real two-writer conflict story. The plumbing is cheap; the browsing UI is not, and it would undo everything the one-tap capture design is for.

## Consequences

**Age decides the writer, so there is only ever one.** The band owns sets in the current workout; the phone owns everything before it. No conflict resolution is needed, because no record is writable in two places at once — Revision numbers pick a winner, but we never rely on them to, and that is deliberate.

Revisions compose cleanly with at-least-once delivery: a replayed `rev: 1` is still a no-op under upsert-if-higher-revision, so editability costs nothing in the delivery model.

The band's local log stays **permanently bounded** — one workout, plus one Last Set Memory row per catalogue exercise. Once the phone acknowledges a set and it falls out of the current workout, the band's copy is redundant and is dropped.

Deletion is a tombstone (same id, higher revision), not an erasure — except inside the Hold Window, where the set has never left the band and Undo simply pops it off the Outbox.
