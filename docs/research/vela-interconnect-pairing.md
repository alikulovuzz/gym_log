# What `@system.interconnect` can pair with

_Research for [Determine what @system.interconnect can pair with](https://github.com/alikulovuzz/gym_log/issues/4). Written 2026-07-14._

## Verdict: CONDITIONALLY OPEN (medium-high confidence)

A **third-party Android app you control _can_ be the phone-side counterpart** of a sideloaded Vela quick app. `interconnect` is not hard-wired to Mi Fitness at the API level — routing is by **package name + signing key**, and Xiaomi ships an official Android SDK (`com.xiaomi.xms.wearable.*`) that any app can link. This is the "open" world the ticket hoped for.

**But there is a gate.** Xiaomi requires the third-party app to be **authorised ("bond")** before the band will actually route its messages. Without that authorisation, Mi Fitness never announces the app as "online" to the band, and the band **silently drops the app's messages even when package and signature match**. For a personal, never-published app there are only two ways past the gate:

1. **Xiaomi partner onboarding** — tied to the store/developer process, which this effort has ruled **out of scope**; or
2. **A rooted phone running an Xposed hook** (MiWearBridge / Wearable-Debug on LSPosed) that forges the "online" signal inside Mi Fitness.

So the honest verdict is: the channel exists and reaches _our_ app, but reaching it **without Xiaomi's blessing requires rooting the companion phone**. Whether that's acceptable is now the pivotal follow-up decision.

**Strongest single piece of evidence:** the [MiWearBridge README](https://github.com/batareya16/MiWearBridge) — a working reverse-engineering project that documents exactly this gate and how it is bypassed — corroborated by **real matched app pairs on GitHub** (band `.rpk` + Android companion) using the official `com.xiaomi.xms.wearable` SDK, e.g. [zaona/simple-weather](https://github.com/zaona/simple-weather) ↔ [zaona/simple-weather-syncer](https://github.com/zaona/simple-weather-syncer).

**One important gap:** every confirmed working example is on **Band 8 Pro / Band 9 / Watch S1**. I found **no direct confirmation of interconnect on Band 10**. That remains an on-device experiment (ticket [Install our own self-built .rpk on the band](https://github.com/alikulovuzz/gym_log/issues/7)).

---

## 1. What can `interconnect` pair with, and how is it bound?

**Bound by package name + signing key — designed for third-party Android apps.** The official docs state the counterpart is "a third-party Android app", and binding is by matching identity, not a Xiaomi-issued appid:

> "Ensure that the `package` field in the Quick App's `manifest.json` matches the package name of the third-party Android app to be integrated. The Quick App signature must use the signature of the third-party Android app."
> — [interconnect docs](https://iot.mi.com/vela/quickapp/en/features/network/interconnect.html)

So the contract for _our_ two apps is simply: **same package name declared in the `.rpk` manifest, and the `.rpk` signed with the same key as the Android APK.** No store appid is required by the transport itself. (Evidence: hard — official docs, plus [zaona/simple-weather-syncer README](https://github.com/zaona/simple-weather-syncer) which drives exactly this via `ANDROID_PACKAGE_NAME` + `ANDROID_CERT_SHA1` env vars matched to the quick app.)

The band-side API is a singleton connection (evidence: hard — official docs + real source [zaona/simple-weather `connection-service.js`](https://github.com/zaona/simple-weather/blob/main/src/common/js/connection-service.js)):

```js
import interconnect from "@system.interconnect"
const connection = interconnect.instance()
connection.onopen    = (data) => { /* data.isReconnected */ }
connection.onmessage = (data) => { ... }
connection.onerror   = (error) => { /* 1001 = phone app not installed, 1006 = connection lost */ }
connection.onclose   = (data) => { ... }
connection.send({ data })
```

## 2. Is there a phone-side SDK?

**Yes — an official one.** The companion app links `xms-wearable-lib_1.4_release.aar` and calls `com.xiaomi.xms.wearable.*`. Confirmed API surface from a real working companion ([zaona/simple-weather-syncer `WearableMessageHandler.java`](https://github.com/zaona/simple-weather-syncer/blob/main/android/app/src/main/java/com/application/zaona/weather/WearableMessageHandler.java)):

```java
NodeApi    nodeApi    = Wearable.getNodeApi(context);     // find the connected band ("node")
MessageApi messageApi = Wearable.getMessageApi(context);  // send/receive raw byte messages
AuthApi    authApi    = Wearable.getAuthApi(context);     // request/check permissions per node
NotifyApi  notifyApi  = Wearable.getNotifyApi(context);   // push notifications to the band
ServiceApi serviceApi = Wearable.getServiceApi(context);  // service (Mi Fitness) connection lifecycle

nodeApi.getConnectedNodes()...                 // -> list of Nodes; take nodes.get(0)
authApi.requestPermission(node.id, perms)...   // user grants in Mi Fitness
messageApi.sendMessage(node.id, bytes)...      // phone -> band
messageApi.addListener(node.id, listener)      // band -> phone
nodeApi.isWearAppInstalled(node.id)...
nodeApi.launchWearApp(node.id, launchPath)...  // wake the quick app
```

This is a clean, sufficient API for the gym-log sync: `messageApi.addListener` receives sets pushed from the wrist. (Evidence: hard — real source code.)

**Note on library provenance.** [Notify's VelaJS guide](http://www.mibandnotify.com/xiaomi-mi-band/notify-xms-app-instructions.php) warns that for use _with Notify_ you must use a specific `xms-wearable-lib` build and "NOT the official Xiaomi SDK". That's a Notify-specific transport detail; the zaona pair above uses the standard `com.xiaomi.xms.wearable` classes directly against Mi Fitness. Both are the same API shape.

## 3. What is the transport, and is Mi Fitness required?

**Mi Fitness (or Mi Health) is the mandatory hub.** The companion app checks for it and refuses to connect otherwise (evidence: hard — real source):

```java
packageManager.getPackageInfo("com.mi.health", 0);      // Mi Health, or
packageManager.getPackageInfo("com.xiaomi.wearable", 0); // Mi Fitness
```

The band talks BLE to whichever hub app is bonded to it; the `xms-wearable` SDK in _our_ app binds to that hub's `com.xiaomi.wearable.XMS_WEARABLE_SERVICE` and rides its existing BLE link. Our app never speaks BLE to the band directly — it speaks to Mi Fitness, which relays. (Evidence: hard — [MiWearBridge `BypassBondClient.java` header comment](https://github.com/batareya16/MiWearBridge/blob/main/app/src/main/java/com/batareya16/miWearBridge/xp/BypassBondClient.java): _"The xms-wearable-lib SDK hard-binds to the Notify package (com.mc.xiaomi1) via the com.xiaomi.wearable.XMS_WEARABLE_SERVICE action. Mi Fitness (com.xiaomi.wearable) exposes the same service…"_)

## 4. The "bond" gate — why matching package + signature is not enough

This is the crux, and the ticket's "closed" fear made concrete. From the [MiWearBridge README](https://github.com/batareya16/MiWearBridge):

> "Xiaomi's `interconnect` (watch quick-app ↔ phone app) officially requires the third-party app to be **authorised by Xiaomi ("bond")**. Without it the band **silently refuses to route** the app's messages — even when package and signature match. The transport itself carries no authorisation: routing is purely by package, and _'is this app's companion online'_ is decided on the phone via `syncPhoneAppStatus` (device command `20/7`). The original failure was simply that Mi Fitness never sent that signal for an unauthorised app."

So the gate lives on the **phone**, inside Mi Fitness, not in the band firmware or the transport. That's what makes the Xposed bypass possible: MiWearBridge hooks Mi Fitness to (a) redirect the SDK bind target, (b) swallow the client-side `not bond` exception, (c) return a forged `WatchAppItemEntity` with the correct SHA-1 fingerprint, and (d) **announce the app as online via `syncPhoneAppStatus`** — "the signal that actually opens the watch-side channel". (Evidence: hard — README + source; this is reverse-engineering, so treat the exact command numbers as the author's findings rather than Xiaomi documentation.)

MiWearBridge also adds **coordinator routing**: many watch quick-apps → one phone app, with a `@w:<watchPackage>\n` payload prefix for phone→watch addressing. Useful later but not needed for a single gym-log app.

**Requirements for the bypass route** (evidence: hard — README):
- Rooted phone with **LSPosed** (Xposed API 82+), hooking **both** Mi Fitness and the companion app.
- Watch `.rpk` and phone app **share the same signing key**.
- Mi Fitness set to no battery restriction for background sync.

Confirmed working on **Mi Band 8 Pro and Mi Band 9** via example apps ([MiBand8ProHassControlApps](https://github.com/batareya16/MiBand8ProHassControlApps), the zaona weather pair). **Not yet confirmed on Band 10.**

## 5. What happens to `interconnect` for a sideloaded app?

Sideloading the `.rpk` (via Notify for Xiaomi, modded Mi Fitness, or Gadgetbridge's RpkService) installs and runs the app fine. The [Gadgetbridge RpkService thread](https://codeberg.org/Freeyourgadget/Gadgetbridge/issues/3786) confirms `.rpk` parse/install/list/delete works and was merged (March 2026), verified on Band 9 and Band 8 Pro. **But installation ≠ a working interconnect channel** — the channel still depends on the phone-side bond announcement from §4. A sideloaded app that never went through Xiaomi's store has no bond, so on a stock (unrooted) phone its `interconnect` messages are silently dropped. (Evidence: hard for install; strong inference for the channel, directly supported by the MiWearBridge README.)

## 6. Does Band 10 support `@system.fetch`? — NO

The official [fetch docs support table](https://iot.mi.com/vela/quickapp/en/features/network/fetch.html) lists **Xiaomi Band 10 as "Not supported"** (alongside Band 8 Pro, Band 9 / 9 Pro, Redmi Watch 4, and the ECG/BP Recorder). (Evidence: hard — official docs.)

**Consequence:** the band has **no independent internet**. There is no `fetch` escape hatch. The _only_ ways data leaves the wrist are `interconnect` (this ticket) or **raw BLE** (fallback ticket [Fallback sync channel](https://github.com/alikulovuzz/gym_log/issues/8)). This makes the pairing question load-bearing exactly as the map predicted.

---

## Delivery guarantees (message size, buffering, dedup)

**Largely undocumented — a real gap.** The official interconnect page does not state message size limits, throughput, or disconnected-queue behaviour. From the API and code:

- **Payload:** `messageApi.sendMessage(nodeId, byte[])` — raw bytes, so app-level framing/JSON is on us. No documented size cap found; assume small (a set is tiny, so likely fine, but chunk defensively).
- **Connection state is explicit and reconnect-aware:** band-side `onopen` carries `data.isReconnected`, and the zaona app re-runs a handshake on reconnect — implying the framework drops the connection when the phone is away and re-establishes it, rather than transparently buffering. Error `1001` = phone app not installed, `1006` = connection lost.
- **No evidence of automatic offline queueing.** Practically: **the band app must persist unsynced sets to local storage and drain the backlog on `onopen`/reconnect**, and the phone must dedup (idempotency key per set). This directly informs the map's "sync semantics" fog. (Evidence: strong inference from real source + error codes; not from a spec.)

---

## If we can't/won't root: what's the next concrete step

The verdict is conditionally open, so the follow-up decision is **"is rooting the companion phone acceptable?"** That splits the route:

- **Root acceptable →** the path is proven-in-kind (Band 8 Pro/9). Next: confirm the same on **Band 10** hardware — build a trivial `.rpk` that `send()`s a ping, a companion app that logs received bytes, install MiWearBridge, and watch a message arrive. Folds into tickets [Install our own self-built .rpk on the band](https://github.com/alikulovuzz/gym_log/issues/7) and toolchain [Get the Vela toolchain building an .rpk](https://github.com/alikulovuzz/gym_log/issues/3).
- **Root NOT acceptable →** interconnect on a stock phone needs Xiaomi bond authorisation, which is tied to the (out-of-scope) partner/publish process. Then **[raw BLE fallback](https://github.com/alikulovuzz/gym_log/issues/8) becomes the critical path** — our Android app would talk BLE to the band directly, bypassing Mi Fitness and its bond gate entirely. Whether a Vela app can even open a raw BLE GATT server the phone can reach is that ticket's open question.

Either way, interconnect is **not dead** — it's gated, and the gate's cost is "root the phone."

---

## Open questions / could not determine

- **Band 10 specifically.** No confirmed interconnect-over-Band-10 example. Every working pair I found is Band 8 Pro / Band 9 / Watch S1. Only an on-device test settles it.
- **Exact message size / throughput limits.** Not documented; not found in sample code. Needs an empirical probe.
- **Whether Notify for Xiaomi offers a _non-root_ interconnect bridge.** Notify clearly installs `.rpk`s and ships a special `xms-wearable-lib`, but I could not confirm from its public docs whether it relays arbitrary third-party interconnect traffic without root, or only bridges its _own_ app. Worth a direct check of Notify's changelog/support before assuming root is mandatory.
- **Bond longevity.** Whether the MiWearBridge forge survives Mi Fitness updates / band firmware updates is unknown — relevant to the map's "app survival" fog.
- **`syncPhoneAppStatus` / device command `20/7`** are reverse-engineered identifiers from MiWearBridge, not Xiaomi documentation — reliable enough to act on, but not vendor-confirmed.

## Sources

- [interconnect API (official)](https://iot.mi.com/vela/quickapp/en/features/network/interconnect.html)
- [fetch device-support table (official) — Band 10 "Not supported"](https://iot.mi.com/vela/quickapp/en/features/network/fetch.html)
- [MiWearBridge — the bond gate + Xposed bypass, documented](https://github.com/batareya16/MiWearBridge) ([`BypassBondClient.java`](https://github.com/batareya16/MiWearBridge/blob/main/app/src/main/java/com/batareya16/miWearBridge/xp/BypassBondClient.java))
- Real matched pair using the official SDK: band [zaona/simple-weather](https://github.com/zaona/simple-weather) ↔ companion [zaona/simple-weather-syncer](https://github.com/zaona/simple-weather-syncer) ([`WearableMessageHandler.java`](https://github.com/zaona/simple-weather-syncer/blob/main/android/app/src/main/java/com/application/zaona/weather/WearableMessageHandler.java))
- Other companions linking `xms-wearable-lib`: [leset0ng/BandTOTP-Android](https://github.com/leset0ng/BandTOTP-Android), [andyching168/MiBandGMaps-Android](https://github.com/andyching168/MiBandGMaps-Android), [phucdt1234/Vietnav-companion-app](https://github.com/phucdt1234/Vietnav-companion-app)
- [Gadgetbridge RpkService thread — .rpk install confirmed on Band 9 / 8 Pro](https://codeberg.org/Freeyourgadget/Gadgetbridge/issues/3786)
- [Notify for Xiaomi — VelaJS / interconnect developer guide](http://www.mibandnotify.com/xiaomi-mi-band/notify-xms-app-instructions.php)
