# Map: Gym-log app on the Xiaomi Smart Band 10

Label: `wayfinder:map`

## Destination

A **gym-logging Vela quick app running on my own Xiaomi Smart Band 10** (Global, Android-paired), which records sets — exercise, weight, reps — offline on the wrist, and **automatically delivers them to a companion Android app I control**. The route is proven end-to-end on real hardware, not just in an emulator.

Reaching the destination means: I can walk into a gym, log a set on the band with no phone in hand, and afterwards find that set in my own Android app without doing anything manual.

## Notes

**Domain.** Xiaomi Smart Band 10 runs **Vela OS**. Third-party apps are **Vela JS Quick Apps** — JavaScript, packaged as **`.rpk`**. This is an officially documented platform, not a hack:

- Official docs: https://iot.mi.com/vela/quickapp/en/
- Toolchain: `npm create aiot` → `aiot build` → `.rpk`; an emulator exists (`aiot start`)
- JS API families: Basic Features, Network Access (`@system.fetch`, **`@system.interconnect`**), Data Files (storage + file), System Capabilities (sensors, vibration, battery, **bluetooth**), Security (crypto), Others (popup, audio)
- **`@system.interconnect`** is the phone channel: a singleton connection to "the paired mobile app", with `connect.send({data})`, `onmessage`, `onopen`, `onclose`. Band→phone data exchange is a first-class supported feature.
- Sideloading onto a real band is the **community** part, and the risky part: **Notify for Xiaomi** (*update section → third-party app (RPK)*), or **@m0tral's modded Mi Fitness**. Community `.rpk` repository: **bandbbs.cn**.
- Warning sign: the `@system.fetch` docs list Band 8 Pro / Band 9 / 9 Pro / Redmi Watch 4 as **not supported**, so the band likely has **no independent internet**. If Band 10 is the same, `interconnect` (or raw BLE) is the *only* data path off the wrist — load-bearing, not one option among several.
- Warning sign: r/miband reports of Global-firmware bands where the install tools "do not detect MI band 10 at all". Global firmware is the single biggest feasibility risk in this map.

**This map carries execution.** Wayfinder is normally planning-only. Overridden here: the central questions — *does a self-built `.rpk` install on a Global Band 10?*, *can `interconnect` reach an app that isn't Mi Fitness?* — cannot be answered by reasoning or by reading docs. They are settled only by putting an artifact on the hardware. Tickets may therefore build, sign, sideload and run real code. The map is still done when the *way* is clear, not when the product ships.

**Hardware/context facts** (established while charting, do not re-ask):
- Band: Xiaomi Smart Band 10, **Global/International** version
- Phone: **Android**
- Sync target: **the user's own Android companion app** (not a file, not a third-party fitness app)
- User is a strong dev across multiple languages; keep tickets terse and aim straight at the unknowns

**Skills every session should consult:** `/grilling` and `/domain-modeling` for HITL tickets; `/prototype` for UI/logic questions; `/research` for docs work.

## Decisions so far

<!-- one line per resolved ticket: gist + link -->

_(none yet)_

## Not yet specified

- **Sync semantics.** When does a set actually leave the wrist — per set, per exercise, at end of workout, or on reconnect? What happens to sets logged while the phone is in a locker across the gym (buffering, backlog drain)? Idempotency and dedup on the phone side, so a redelivered set isn't double-counted. Sharpens once [Determine what @system.interconnect can pair with](issues/03-interconnect-pairing-model.md) names the actual channel and its delivery guarantees.
- **The Android companion app itself.** Architecture, local storage, and — the crux — *how it binds to the band app* so the band knows to talk to it. Cannot be specified before the pairing model is known.
- **App survival.** Do sideloaded apps persist across band firmware updates, or does Mi Fitness wipe them? Does the app survive a band reboot / factory-reset-on-unpair? Affects whether unsynced logs can be lost.
- **Battery and session lifetime.** Cost of an app kept alive through a 90-minute workout; whether the band lets an app run with the screen off at all.
- **Workout ergonomics beyond set entry.** Rest timer, plate math, previous-session recall — the things that make it worth wearing. Deliberately deferred until basic set entry is proven possible.

## Out of scope

- Publishing to Xiaomi's official quick-app store, and any Xiaomi developer-certificate / review process. This is a personal-use app; the sideload route is the route.
- iOS / iPhone support. The band is paired to Android and every install tool is Android-only.
- Watchfaces, and games. Interesting neighbours, not the destination.
- Reverse-engineering or reflashing band firmware. If the app route fails, that is a different effort with a different destination, not a continuation of this one.
