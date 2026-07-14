# Gym Log

A gym-logging app split across two devices: a **Vela quick app on a Xiaomi Smart Band 10**, which captures sets at the rack with no phone in hand, and an **Android companion app**, which is where the training history actually lives. The band is a capture device; the phone is the record.

## Language

### The things being logged

**Set**:
One performance of one exercise: an `Exercise`, a `Weight`, and a count of `Reps`. The atomic unit of the whole system — the only thing the band creates, and the only thing that crosses the wire.
_Avoid_: Rep (a set is not a rep), entry, record

**Exercise**:
A named movement that sets are performed against — "Barbell Bench Press", "Push-up". A *definition*, not an event: it exists whether or not it has ever been performed. Referenced everywhere by stable `ExerciseId`, never by name.
_Avoid_: Movement, lift, workout (a workout is not an exercise)

**Weight**:
The external load on a set, in **kilograms**, in 0.5kg steps. **Zero means bodyweight** — a push-up is weight 0, a weighted pull-up with a 15kg belt is weight 15. There is no separate "bodyweight exercise" shape.
_Avoid_: Load, resistance

**Reps**:
A whole count of repetitions in a set. Never zero, never fractional. Time-based holds (planks) are not modelled — they have no reps, so they are not sets.

**Session**:
A contiguous block of training — what a person calls "my Tuesday workout". A **derived** concept, not a stored one: the phone infers session boundaries from gaps between set timestamps. **The band has no notion of a session** and never creates, starts, or ends one.
_Avoid_: Workout (as a stored entity), training day

**Current Workout**:
The band's local, rolling view of "the sets I have logged recently" — the window within which a set can still be edited on the wrist. Distinct from `Session`: a Session is the phone's considered judgement after the fact, a Current Workout is the band's working memory during it.

### Capture, on the band

**Current Exercise**:
The exercise the band is "in" right now. Selected once, then sets are logged against it repeatedly without re-selecting. Band-local UI state — it is never synced and has no meaning on the phone.

**Pre-fill**:
The weight and reps the set-entry screen is already showing when you arrive at it, taken from the last set of the Current Exercise. Makes the common case — same weight, same reps as last time — a single tap.

**Last Set Memory**:
A small, permanent map of `ExerciseId → (Weight, Reps)` held on the band, one row per exercise, that outlives any workout. The sole source of Pre-fill. It is *not* history: it remembers only the most recent set of each exercise, and it survives precisely because it is tiny.
_Avoid_: History, cache

**Catalogue**:
The list of Exercises the band can choose from. Hardcoded into the `.rpk` for v1, later owned by the phone. The band never authors an exercise — there is no keyboard on a 1.7" screen.
_Avoid_: Exercise list, library

### Getting sets off the wrist

**Outbox**:
The band's durable store of sets not yet acknowledged by the phone. **Sacred**: a set in the Outbox exists nowhere else in the world, so it is never dropped, never pruned, and never silently discarded. If the Outbox cannot grow, the band refuses to log and says so loudly.

**Hold Window**:
A deliberate delay between logging a set and the set becoming eligible to send — so that Undo is reliable rather than a race against the radio. Sync latency is not a virtue; nothing downstream cares whether a set arrives now or in ten minutes.

**Undo**:
Removing the most recently logged set. Within the Hold Window this is a pure Outbox pop — the set never existed as far as the phone is concerned. After it has synced, it becomes a Revision (a tombstone), not an erasure.

**SetId**:
The identity of a set, minted **on the band at the moment of capture** as `(InstallId, counter)`. Never changes, no matter how many times the set is sent, revised, or replayed. The band has no network and no server, so identity cannot come from anywhere else.

**InstallId**:
A random id minted once, on the band, on first launch. Namespaces the band's set counter so that a reinstall cannot collide with sets logged before it.

**Revision**:
A version number on a set, band-minted, starting at 0. An edit or a deletion re-sends the *same* `SetId` with a higher Revision. The phone keeps the highest Revision it has seen.

**Acknowledgement**:
The phone confirming, by `SetId`, that it holds a set. The only thing that permits the band to drop a set from its Outbox.
_Avoid_: Ack receipt, confirmation

**Upsert**:
How the phone accepts a set: insert it, or overwrite the existing one **if the incoming Revision is higher**. Makes redelivery a no-op, which is what allows delivery to be at-least-once without duplicating sets in the log.
