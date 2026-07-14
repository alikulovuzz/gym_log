# Determine what @system.interconnect can pair with

Type: research
Status: open
Blocked by: —

## Question

`@system.interconnect` connects a band app to **"the paired mobile app"**. Which mobile app is that, and can it be *ours*?

This is the pivot of the entire second phase. Two very different worlds hang on the answer:

- **Open**: a third-party Android app can register itself as the counterpart of a specific quick app (by package name, app id, or some binding handshake), receive `connect.send({data})` and reply. The gym-log sync is then a solved problem and the companion app is straightforward.
- **Closed**: `interconnect` is hard-wired to Mi Fitness / Xiaomi Wear, and a sideloaded app has no way to reach an arbitrary Android app. Then the destination needs a different channel entirely, and ticket 07 (raw BLE) becomes the critical path.

Chase down, from the official docs first (https://iot.mi.com/vela/quickapp/en/features/network/interconnect.html and its neighbours) and community sources second:

- Is there a **phone-side SDK** — an Android library or intent/service contract that a companion app implements? Xiaomi's wearable ecosystem docs, any `RpkService` / Mi Wear SDK.
- How is the band app **bound** to its phone counterpart — by manifest declaration, package name, appid, or something issued by Xiaomi at publish time? (If binding requires an appid from Xiaomi's store, note that publishing is out of scope — and whether that blocks us anyway.)
- What are the **delivery guarantees**: message size limits, throughput, queueing while disconnected, whether the band buffers or drops.
- What happens to `interconnect` for a **sideloaded** app that never went through the store.
- Also confirm whether Band 10 supports `@system.fetch` at all — the docs list Band 9/9 Pro as **not supported**, and if Band 10 inherits that, there is no independent-internet escape hatch.

Also worth checking: Gadgetbridge's `RpkService For Xiaomi Device` issue (codeberg.org/Freeyourgadget/Gadgetbridge/issues/3786) — the reverse-engineering community will have hit exactly this wall.

## Notes

AFK research. Produce a markdown summary as a linked asset.

This ticket clears the largest patch of fog on the map. Its answer graduates the "sync semantics" and "Android companion app" fog into real tickets — or condemns the interconnect route and promotes ticket 07.
