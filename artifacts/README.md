# Sideload test artifacts (ticket #7)

Three `.rpk` builds of the same trivial probe app, differing **only** in the two things that
could plausibly get an install rejected — **who signed it** and **what its package id is**.
Install them in order; each paints its own tag on the band's screen, so the band itself tells
you which one is running.

| file | package | signed by | on-screen tag |
|---|---|---|---|
| `gymlog-devkey.rpk` | `com.gymlog.band` | toolkit's bundled default key (`CN=localhost`, self-signed) | `DEV-KEY` |
| `gymlog-ownkey.rpk` | `com.gymlog.band` | **our own** self-generated key (`CN=gymlog`) | `OWN-KEY` |
| `demo-devkey.rpk` | `com.application.watch.demo` | toolkit's bundled default key | `DEMO-ID` |

`demo-devkey.rpk` is a **control**, only needed if the first two are both rejected: it keeps the
stock template's package id, so if it installs where `com.gymlog.band` did not, the blocker is
the **package id**, not the signature.

Neither key is Xiaomi-issued — there is no Xiaomi certificate anywhere in the toolchain. So:

- **both install** → signing is a non-issue; the band does not check who signed.
- **`DEV-KEY` installs, `OWN-KEY` does not** → the band trusts a specific cert, and we are
  pinned to the toolkit's bundled key.
- **neither installs, `DEMO-ID` does** → the package id is being checked, not the signature.
- **none install** → signature verification against a Xiaomi trust root is a real blocker.

The app shows `GYMLOG / IT RUNS / <tag>` on a magenta background with a tap counter. A blank or
black screen means it installed but did not render — a *different* failure from a rejected
install, and the one to watch for given the emulator's black-panel bug (#13).

Rebuild with `cd band-app && bash scripts/build-variants.sh`.
