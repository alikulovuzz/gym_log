# At-least-once delivery, band-minted set ids, idempotent upsert on the phone

Sets are captured offline on the wrist while the phone sits in a locker, so delivery is unreliable by construction and we must choose which failure to tolerate. We chose: **never lose a set**. The band retries until the phone acknowledges, every set carries a stable `SetId` minted on the band at capture, and the phone applies each arrival as an **upsert keyed on that id** — so a redelivered set is a no-op rather than a duplicate.

## Considered Options

**At-most-once** (band sends and forgets) never duplicates, but a silently failed send loses a set forever. A lost set is unrecoverable — it exists nowhere else — while a duplicate is merely visible and fixable. So losing is strictly worse.

**Exactly-once** does not exist over an unreliable link. What we build *simulates* it: at-least-once on the wire, deduplicated at the destination by stable id. The user-visible behaviour is exactly-once; the wire behaviour is not.

The tempting cheap design — band sends on log, phone appends — is at-most-once delivery into a non-idempotent sink, which manages to both lose sets *and* duplicate them. It is the worst of both and must not be built.

## Consequences

The id cannot come from a server (the band has no network) or from a bare counter (which collides across reinstalls), so it is **`(InstallId, counter)`**: a random install id minted on first launch, plus a monotonic local counter. Collision-free without a clock or a UUID library.

The band must have **durable local storage for unsynced sets** (the Outbox), and the phone must be **idempotent from day one**. Neither is hard, but both are load-bearing and cannot be retrofitted — which is why this decision precedes any sync work.

The Outbox is never pruned. If it cannot grow, the band **refuses to log and warns loudly** rather than silently discarding: a user who sees a warning goes and opens their phone, a user who sees nothing loses a month of training.

**When the Outbox drains is deliberately not decided here** — per set, at workout end, or on reconnect depends on what the phone channel turns out to be.
