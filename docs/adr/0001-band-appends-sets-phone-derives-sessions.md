# The band appends timestamped sets; the phone derives sessions from gaps

A gym app "obviously" has a session you start and end. We rejected that: the band has **no session entity**, only an append-only stream of timestamped sets, and the Android app infers session boundaries by looking for large gaps between set timestamps.

## Considered Options

An explicit session — tap **Start Workout**, log sets into it, tap **End Workout** — was the alternative, and it fails in exactly the two ways every app of this shape fails. You forget to start it, and your first two sets vanish. You forget to end it, and Tuesday's session is still open on Wednesday and swallows Wednesday's first set. The universal fix for the second bug is an auto-close timeout, which is gap-detection wearing a costume — so gap-detection is what we build, without the ceremony.

## Consequences

The band's only write is **append one set**. There is no session lifecycle, no open-session state to corrupt, and no "what happens if the band reboots mid-session" question at all — which matters enormously when the hardware itself is unproven.

Session boundaries are corrected on the phone, where there is a real screen and full attention, rather than on the wrist mid-workout.

**This decision depends on a trustworthy wall clock on the band.** If the band's clock is unreliable or resets across reboots, gap-derivation collapses. This must be confirmed while mapping the band's constraints. The fallback, if the clock is bad: the band stamps sets with monotonic uptime and the phone reconciles against arrival time.
