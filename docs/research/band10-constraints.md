# Band 10 constraints for a gym app

Research asset for [#5 — Map the Band 10's constraints for a gym app](https://github.com/alikulovuzz/gym_log/issues/5),
a ticket on [Map: Gym-log app on the Xiaomi Smart Band 10](https://github.com/alikulovuzz/gym_log/issues/1).

**Question:** what does the Band 10 actually give an app to work with, and what will it refuse?

Sources are Xiaomi's official Vela Quick App docs (<https://iot.mi.com/vela/quickapp/en/>, plus the `zh/`
pages where the English build is thinner), the `open-vela` GitHub org, and Xiaomi's own product spec page.
Every claim below is either cited or explicitly marked **[INFERENCE]**. Where the docs say nothing, this
document says **docs do not state** — those silences are findings in their own right, because they are the
things that can only be settled on real hardware.

---

## Headline

**The Band 10 is a real, named target in Xiaomi's docs — and it is one of the most capability-stripped
devices in the range.** It appears by name in the multi-screen design table *and* in the per-API support
matrices, so we are not designing against a device Xiaomi ignores. But the matrices say `fetch`, `network`
and `bluetooth` are all **Not supported** on it.

The three findings that actually reshape the design:

1. **The band is an offline device.** No `@system.fetch`, no `@system.network`, no `@system.bluetooth`.
   `@system.interconnect` is left as the only plausible path off the wrist — and its Band 10 support is
   *not documented either way*.
2. **There is no text input on Vela at all.** Not "no keyboard" — no text-entry component. Entering `85`
   must be built from a picker, swiper, or a hand-rolled stepper.
3. **Screen-off suspends the app; it does not cold-start it.** But no documented background model can keep
   a rest timer running, so all timing must be wall-clock-derived rather than interval-driven.

---

## 1. Screen and input

### The panel

Band 10 is **1.72″ AMOLED, 212 × 520 px, 326 PPI** ([mi.com specs][specs]). Xiaomi's own Vela design docs
corroborate it and name the device: **"Xiaomi Wristband 10 — 1.725 inches, 212×520"**, classified as a
**capsule** (pill-shaped) screen ([Multi-screen Design][multiscreen]).

| Screen shape | Aspect ratio (W/H) | Recommended res | Devices |
| --- | --- | --- | --- |
| Circular | 1 | 466×466 | Watch S3, S4 |
| Rectangular | 0.5 – 1 | 336×480 | Band 8 Pro, REDMI Watch 5 |
| **Capsule** | **0.3 – 0.5** | **192×490** | **Band 9, Band 10** |

Aspect ratio is 212/520 ≈ **0.41** — a tall, narrow strip. Note the trap: Xiaomi's *recommended design
resolution* for capsule is 192×490 (Band 9's native size), which is **not** Band 10's 212×520. Do not
design in absolute pixels.

### Layout units

`px` in Vela is **not** a physical pixel — it is responsive, scaled against `designWidth` in `manifest.json`
(default **480**, not the 750 other quick-app frameworks use) ([page style & layout][layout],
[manifest][manifest]). `dp` (API level 3+) and `%` are also available.

At runtime `device.getInfo()` exposes `screenWidth`, `screenHeight`, `screenDensity`, **`screenShape`**
(`rect` | `circle` | `pill-shaped`) and **`deviceType`** (`watch` | `band` | `smartspeaker`)
([Device Information][device]). Xiaomi's own calculator sample branches its entire layout on
`screenShape === 'pill-shaped'` ([multi-screen-calculator][calc]).

### Input primitives

The complete documented event list ([Common Events][events]):

`touchstart`, `touchmove`, `touchend`, `click`, `longpress`, `swipe` (`{direction: left|right|up|down}`, does
not bubble). Scroll events exist only on the `list` and `scroll` containers.

- **No crown, no rotary, no side-button API.** Nothing in Common Events or `@system.event`. Band 10 has no
  physical crown anyway.
- **Right-swipe is reserved by the system as "back."** `onBackPress()` fires when the user *"swipes right
  to return"* or presses a physical back button; returning `true` intercepts it ([lifecycle][lifecycle]).
  **[INFERENCE]** — a set-entry UI should therefore avoid horizontal swipe gestures and use **vertical**
  ones, which are unclaimed.

### Components

The complete inventory ([Components index][components]):

- **Container:** `div`, `list`, `list-item`, `scroll`, `stack`, `swiper`
- **Basic:** `text`, `span`, `a`, `image`, `image-animator`, `progress`, `marquee`, `chart`, `qrcode`, `barcode`
- **Form:** `input`, `picker`, `switch`, `slider`

**There is no stepper, no number-picker, no textarea, and no dialog/modal component.** The only popup is
`prompt.showToast({message, duration})` ([prompt][prompt]).

The number-entry-capable ones:

| Component | Documented API | Fit for weight entry |
| --- | --- | --- |
| **`picker`** ([doc][picker]) | Only two types exist: `text` and `time`. `range: Array<string>`, `selected: number` (index). Event `change` → `{newValue, newSelected}`. Styleable via `selected-font-size`, `selected-background-color`. | **Best documented option.** A `range` of `["2.5","5",…,"85","87.5",…]` gives a scroll wheel. |
| **`swiper`** ([doc][swiper]) | `index`, `loop`, **`vertical`**, `duration`; event `change` → `{index}`; method `swipeTo({index})`. | Good — `vertical: true` + `loop` is a digit wheel, and `swipeTo()` can pre-seed the last-used value. Vertical avoids the reserved back-swipe. |
| **`slider`** ([doc][slider]) | `min`, `max`, `step`, `value`; `change` → `{progress, isFromUser}` — **fires only on drag completion**, not continuously. | **Poor.** On a 212 px-wide screen a 0–200 kg slider is ~1 px/kg, and there's no live readout while dragging. |
| **`scroll`** ([doc][scroll]) | API level 3+ adds CSS scroll-snap: `scroll-snap-type`, `scroll-snap-align`, `scroll-snap-stop: always`. | Viable for a hand-rolled iOS-style wheel if `picker`'s styling is too limited. **[INFERENCE]** |

### Text input: there isn't any

The `input` component's `type` attribute accepts **only `button | checkbox | radio`** ([input][input]).
There is no `text`, `number`, `password`, or `date` type; there is no `<textarea>`; and **the docs never
mention a soft keyboard or IME.**

The one keyboard that exists is a **third-party component you copy into your source** —
[`NEORUAA/Vela_input_method`][ime], linked from Xiaomi's own [Extension Components][extensions] page. It is
owned by `NEORUAA`, not Xiaomi/`open-vela`, and is a QWERTY/T9 keyboard rendered *as a Quick App component*
— **not** an OS-level IME that a focused field can summon. On a 212 px-wide strip, mid-set, it is not a
realistic input method. **[INFERENCE]**

**No speech/ASR API exists.** `@system.record` ([doc][record]) captures raw audio (`pcm`/`opus`/`wav`) — it
gives you bytes, not text, and the band has no internet to send them anywhere.

**How would a user actually enter "85"?** Xiaomi's sanctioned answer, from their own official
[multi-screen-calculator sample][calc]: **you draw a keypad out of plain `<text>` elements.** There is no
numeric primitive. Ranked for our case (**[INFERENCE]** — the docs express no preference):

1. **Hand-rolled ± stepper** seeded from the previous set's weight, with `longpress` for fast repeat. For
   gym logging the delta from the last set is almost always small or zero, so this is likely the fewest
   interactions. Two big tap targets beat everything else with sweaty hands.
2. **`picker` with a pre-built `range`** of plausible weights — one tap, one scroll, one commit. First-party
   and documented.
3. **Vertical `swiper`s / scroll-snap wheels** as digit columns — more code, full control.
4. **Calculator-style keypad** — precise, but ~10 tiny targets across 212 px. Worst for sweaty fingers.

Pair any of them with `vibrator.vibrate({mode:'short'})` for eyes-free confirmation.

---

## 2. Storage

The full "Data Files" API surface is **two modules: `storage` and `file`** ([features index][features]).
A grep across all 109 English doc pages for `sqlite`, `indexeddb`, `database` returns **zero hits**.
**There is no database** — it is strictly `String → String` key-value plus a POSIX-ish file API. No indexes,
no queries, no transactions, no atomic multi-key write.

### `@system.storage` ([doc][storage])

Four methods, all async/callback-style: `get`, `set`, `delete`, `clear`. **Values are `String` only** —
`JSON.stringify` yourself. There is **no sync variant** and **no key-enumeration API**, so you cannot list
keys; you must maintain your own index key.

**Footgun, quoted:** `value` — *"If the new value is an empty string with a length of 0, deletes the data
item indexed by key."* So `set({key, value: ''})` **silently deletes**. A workout serializing to `""` would
vanish rather than store empty.

The page documents **no error codes at all** — so there is no "quota exceeded" error you could even catch.

### `@system.file` ([doc][file])

`move`, `copy`, `list`, `get`, `delete`, `writeText`, `writeArrayBuffer`, `readText`, `readArrayBuffer`,
`access`, `mkdir`, `rmdir`. All async.

- `writeText` supports **`append: true`** — native append-only logging.
- `readArrayBuffer` supports `position` + `length` → **random-access partial reads**, so one record can be
  read without loading the whole log.
- `list`/`get` return per-file `length` (bytes) — you can measure your own usage at runtime.
- Error codes: `202` param, `300` I/O, `301` not found. **There is no "disk full" code.** **[INFERENCE]** a
  full flash would surface as a generic `300`.
- The only capacity-adjacent statement in the entire doc set, a WARNING on both write methods:
  > *"When using file write interfaces, ensure to clean up unused files promptly, especially on IoT devices
  > with limited memory, to avoid memory overload and application crashes."*

  Note what that says: unbounded writing can **crash the app**, not fail cleanly.

### Partitions — the load-bearing finding

Four URI partitions ([project structure][structure]), quoted:

| Partition | URI | Doc says |
| --- | --- | --- |
| **Files** | `internal://files/` | *"relatively small **permanent** files, managed by the app itself"* |
| Cache | `internal://cache/` | *"**may be deleted by the system** due to insufficient storage space"* |
| Mass | `internal://mass/` | *"**does not guarantee continuous availability**"* |
| Temp | `internal://tmp/` | read-only; *"**cannot be accessed after app restart**"* |

**Unsynced sets MUST live in `internal://files/`.** It is the only partition the docs call permanent.
`cache` is explicitly evictable and `mass` explicitly unguaranteed — either can silently lose a workout.

### Quotas and durability: the docs are silent

- **No storage quota is documented anywhere** — not per key, per value, per file, or per app. A grep of all
  109 pages for `quota`, `max size`, `size limit` and `<n> KB`/`MB` patterns returns **zero hits**.
- **No max `.rpk` size.** [Acceptance criteria][acceptance] is near-empty in the English build;
  [memory best-practice][memory] has a "Reduce Package Size" section with **no numeric ceiling**, only
  qualitative advice, and points at acceptance criteria the public docs never enumerate.
- **Survival across band reboot, app update, or uninstall: docs do not state.** None of these are addressed
  anywhere. There is **no `fsync`/flush primitive**, and no guarantee that a `success` callback means the
  bytes reached flash. **[INFERENCE]** — a reboot immediately after `success` is a real, undocumented
  data-loss window.

### Capacity estimate **[INFERENCE — no doc number to work from]**

At ~30 sets/workout × ~80 bytes of JSON ≈ **2.4 KB per workout**:

- 100 KB → ~1,250 sets ≈ **~40 workouts**
- 1 MB → ~12,500 sets ≈ **~400 workouts** (a year+ of training 4×/week)

The real constraint is almost certainly **not flash bytes** for a text log this size — it's **RAM when you
`readText` the whole file back**, which is exactly what the write-warning is gesturing at. Must be validated
on-device.

---

## 3. Lifecycle — the deep finding

The ticket flagged this as the finding most likely to reshape the design. It is, and it cuts **both ways**.

### Screen-off does NOT cold-start the app

The decisive sentence is on the precautions page, under *"exception scenarios on the watch"* — our exact
device class ([tips, EN][tips] / [ZH][tipszh]):

> 息屏后重新亮屏会重新触发 onShow 生命周期函数，此生命周期函数中如果有 fetch 请求，亮屏时会再次发起请求，需谨慎使用
>
> *"After the screen turns off and then lights up again, **the `onShow` lifecycle function is triggered
> again**; if there is a fetch request in it, the request will be re-issued on wake — use with caution."*

Screen-off produces a **hide/show cycle, not a destroy/create cycle**. The doc's own worry — that a `fetch`
in `onShow` would *re-issue* — only makes sense if the page's JS, its handler, and its closures are all
**still alive**. A cold-started app cannot "re-issue" anything.

**So the nightmare scenario in the ticket — "if the band suspends our app between sets, treat every set as a
cold start, no in-memory state, no running timer" — is probably NOT required.** State survives.

### But nothing documented can keep a timer running

The entire background model is one short page ([Background Running][background]). An app that backgrounds
*"will be stopped"* unless **both**: the background interface is declared in `manifest.json`, **and** at
least one declared background interface is **actively running**.

The whitelist is **exactly three features, and there are no others**:

| Feature | Purpose |
| --- | --- |
| `system.audio` | audio playback |
| `system.request` | upload / download |
| `system.geolocation` | geolocation |

```json
{ "config": { "background": { "features": ["system.audio", "system.request"] } } }
```

**A gym rest timer matches none of them.** This is a *capability-gated* model, not a time-gated one — there
is no generic background task, no "run for N more seconds", no service worker, no headless JS. Condition 2
is the killer: declaring `system.audio` isn't enough, audio must actually be *playing*.

The docs also direct that background work live in **`app.ux`, not in a page** — consistent with pages being
the destroyable unit.

### The wake-lock — our escape hatch

**`brightness.setKeepScreenOn({keepScreenOn: Boolean})`** ([doc][brightness]) is a real wake-lock. If the
screen never turns off, the app never backgrounds, and the whole problem evaporates.

Caveats: the docs **do not state** how long it persists, whether `onHide` clears it, or whether the system
overrides it — and **the page carries no device-support table**, so *Band 10 support is unknown.* Gate it
behind `app.canIUse('@system.brightness.setKeepScreenOn')` ([app][app]) rather than trusting it. Obvious
cost: screen-on for 60–90 minutes on a band is a battery question.

### Timers

**`setTimeout`/`setInterval` are not documented as an API** — there is no timer module in the JS API index,
and [Global Attributes and Methods][globals] lists only framework `$` methods. But the
[startup-latency page][start] tells you to *avoid `setTimeout` delays* — you cannot avoid what does not
exist. **[INFERENCE, high confidence]** they are available as ECMAScript globals.

**Whether they are throttled or frozen in the background is documented NOWHERE.** Not one sentence, either
way. Combined with *"will be stopped"*, the natural reading is **frozen JS, surviving memory**
(**[INFERENCE, medium confidence]** — this synthesizes two doc pages that never reference each other).

### What kills an app — largely undocumented

**Documented:** pages are destroyed *"when the user has opened too many pages and the framework
automatically destroys some pages to free resources"* ([lifecycle][lifecycle]) — **the framework will
destroy PAGES out from under you**, so workout state must not live only in a page ViewModel. Memory is
documented as tight ([memory][memory]) with **no MB limit and no OOM-kill policy** given. `app.terminate()`
exists for self-exit.

**Not documented anywhere — say this loudly:**

- ❌ **No inactivity/idle timeout rule.** There is no "backgrounded for N minutes then destroyed" anywhere.
- ❌ **No whole-app memory-pressure kill policy** (page eviction is documented; app kill is not).
- ❌ **Nothing about another app opening**, or returning to the watchface, evicting ours.
- ❌ **Nothing whatsoever about the built-in Mi Fitness / workout app.** No interaction, no priority rule.
  A first-party workout session claiming screen and sensors is *precisely* the kind of thing that would
  evict a third-party app — and we would never learn it from the docs. **Real risk, total doc blank.**
- ❌ **How a user physically re-enters the app on a band.** No app-switcher, no recents, nothing about the
  band's shell is documented.
- ❌ **Whether re-launching a backgrounded app resumes (`onShow`) or cold-starts (`onCreate`).** The
  [launch-mode][launchmode] doc governs the *page stack within a running app*, not the process. Striking
  omission: the startup-latency page never distinguishes cold from warm start.

### Hooks, for reference

App (`app.ux`): `onCreate`, `onShow`, `onHide`, `onDestroy`, `onError`.
Page: `onInit` (data ready) → `onReady` (template compiled) → `onShow` … `onHide` … `onDestroy`, plus
`onBackPress` and `onRefresh(query)` (fires when an existing page is re-opened under `singleTask`).

`launchMode: "singleTask"` + `onRefresh` is the re-entry contract — re-launching lands on the same page
instance rather than stacking a duplicate ([launch mode][launchmode]).

---

## 4. Sensors, haptics, battery

### Vibration — one blunt instrument

`@system.vibrator` ([doc][vibrator]). The support table is explicit about Band 10:

| Method | Band 10 |
| --- | --- |
| `vibrate({mode: 'long' \| 'short'})` | **Supported** |
| `start({duration, interval, count})` | **Not supported** (Watch S5 only) |
| `stop(taskId)` | **Not supported** (Watch S5 only) |
| `getSystemDefaultMode()` | **Not supported** (Watch S5 only) |

**On Band 10 you get exactly one haptic primitive: a fire-and-forget `vibrate({mode})`.** No duration, no
intensity, no repeat count, and **no cancel**. Any buzz pattern must be composed from multiple `vibrate()`
calls driven by our own timers — which is precisely the thing that may be frozen with the screen off.

Note also that `system.vibrator` is **not on the background-eligible whitelist**, so a buzz that must fire
while the screen is off is **the single biggest open risk in the project**.

### Heart rate — does not exist

The complete JS API module list is: `app`, `configuration`, `device`, `router`, `fetch`, `interconnect`,
`request`, `uploadtask`, `storage`, `file`, `network`, `vibrator`, `brightness`, `record`, `geolocation`,
`sensor`, `event`, `battery`, `volume`, `zip`, `bluetooth`, `crypto`, `audio`, `prompt`.

**There is no health, heart-rate, SpO2, sleep, or step-counter module.** This is not a permissions problem
and not a Band 10 exclusion — **the API does not exist in the framework.** Any feature premised on heart
rate is dead on arrival.

### Sensors — `@system.sensor` ([doc][sensor])

The only sensors exposed are pressure, accelerometer, compass.

| Sensor | Band 10 |
| --- | --- |
| `subscribeAccelerometer` (`{x,y,z}`, interval `game` ~20 ms / `ui` ~60 ms / `normal` ~200 ms) | **Supported** |
| `subscribePressure` (hPa) | **Supported** |
| `subscribeCompass` | **Not supported** |

Accelerometer is subscribe-only with no background guarantee, so the same freeze caveat applies to any
rep-counting idea.

### Battery — `@system.battery` ([doc][battery])

`getStatus()` → `{charging: Boolean, level: Number}` where level is **0.0–1.0** (a fraction, not a
percentage). **Supported on Band 10** (and notably *not* on Band 8 Pro / Band 9 / Watch S3).

### Device info — `@system.device` ([doc][device])

`getInfo()` → `brand`, `model`, `product`, `osVersionName/Code`, `platformVersionName/Code`, **`APILevel`**,
`screenWidth/Height/Density/Shape`, `deviceType`. `getDeviceId()`/`getSerial()` need
`hapjs.permission.DEVICE_INFO` declared in the manifest. `getTotalStorage()`/`getAvailableStorage()` return
bytes — useful for measuring the undocumented storage ceiling on-device.

---

## 5. API level

`APILevel` identifies the framework's interface set; unmarked APIs are level 1, and anything newer carries a
superscript (`APILevel2+`) ([version notes][version]). Only **four levels exist**:

| Level | Added |
| --- | --- |
| 1 | baseline |
| 2 | `barcode`, `qrcode`, `image-animator`, `scroll`; `getBoundingClientRect`; `deviceType` + `APILevel` on `getInfo()` |
| 3 | `box-shadow`; `$canIUse`; scroll-snap; `@system.uploadtask`; `screenDensity`, `pill-shaped`; the `dp` unit |
| 4 | `@system.event` |

**There is no device→API-level table anywhere. Docs do not state Band 10's level.** The only documented
answer is **runtime detection**: `device.getInfo().APILevel`, or `app.canIUse('@system.x.y')` ([app][app]).

**[INFERENCE]** — Band 10 is documented as supporting `@system.event`, which was *only added in APILevel 4*.
Therefore **Band 10 must expose APILevel ≥ 4**, i.e. effectively the current top level. Deduced from two doc
facts, not stated by Xiaomi; verify at runtime.

### Manifest

It is **`minAPILevel`** (Integer, default 1), *not* `minSdkVersion`/`minPlatformVersion` ([manifest][manifest]).
*"If not filled, it will be treated as a beta version"* — so always set it explicitly.

**Doc bug worth knowing:** the property table documents `minAPILevel`, but the example block on the *same
page* shows `"minPlatformVersion": 1000` — a stale hapjs-heritage field that appears nowhere in the spec.
Trust `minAPILevel`.

Also: `features` — *"Most interfaces need to be declared here; otherwise, they cannot be called."*
`deviceTypeList` — options are `watch | tv | car | phone`, *"currently only watch is supported"*. **There is
no `band` value**, even though `getInfo().deviceType` *can return* `band`. That inconsistency is unresolved
in the docs; the official band-targeting samples all declare `deviceTypeList: ["watch"]`.

---

## 6. The device support matrix — and why the band is offline

The matrix is **not one central table** — it is a per-page *"Support Details"* section at the bottom of each
API doc. The Band 10 **is** listed. Verdicts gathered:

| API | Band 10 | Source |
| --- | --- | --- |
| **`@system.fetch`** (internet) | **Not supported** | [fetch][fetch] |
| **`@system.network`** (net info) | **Not supported** | [network][network] |
| **`@system.bluetooth`** | **Not supported** — Watch S5 is the *only* supported device | [bluetooth][bluetooth] |
| `@system.vibrator` → `vibrate` | Supported | [vibrator][vibrator] |
| `@system.vibrator` → `start`/`stop`/`getSystemDefaultMode` | **Not supported** | [vibrator][vibrator] |
| `@system.battery` | Supported | [battery][battery] |
| `@system.event` | Supported | [event][event] |
| `@system.sensor` → accelerometer, pressure | Supported | [sensor][sensor] |
| `@system.sensor` → compass | **Not supported** | [sensor][sensor] |
| **`@system.interconnect`** | **No support table on the page at all** | [interconnect][interconnect] |

**This confirms the map's warning sign, and sharpens it.** The Band 10 has no independent internet — and it
is worse than just `fetch`: `bluetooth` is out too, so **the raw-BLE fallback channel contemplated in
[#8](https://github.com/alikulovuzz/gym_log/issues/8) appears to be closed at the API level.**

That leaves **`@system.interconnect` as the only plausible sync path off the wrist**, and its Band 10 status
is *not documented either way* — which makes
[#4 — Determine what @system.interconnect can pair with](https://github.com/alikulovuzz/gym_log/issues/4)
the load-bearing ticket on the whole map.

**Coverage caveat:** the following pages were **not** checked for Band 10 verdicts and remain unverified:
`basic/{app, configuration, device, router}`, `data/{file, storage}`, `network/{request, uploadtask}`,
`other/{audio, prompt}`, `security/crypto`, `system/{brightness, geolocation, record, volume, zip}`.
**`data/storage` is the most load-bearing of these** — local persistence is unverified for Band 10.

---

## Design consequences

1. **Design local-first and offline.** The band cannot reach the internet and cannot speak Bluetooth. All
   logging is on-wrist; sync is a separate, deferred concern routed through `interconnect`.
2. **Write unsynced sets to `internal://files/`, never `cache` or `mass`** — those are documented as losable.
   Append-only JSON-lines, one file per workout: bounds any single read, makes each write O(1), and a torn
   write at reboot costs at most the last line rather than the whole log.
3. **Keep the unsynced queue out of `@system.storage`.** No quota, no key enumeration, no error codes, and
   `value: ''` silently deletes. Use it only for small scalars (last-sync cursor, settings). **[INFERENCE]**
4. **Make the rest timer wall-clock-derived, not interval-driven.** Persist `restStartedAt` (epoch ms); on
   `onShow`, recompute `elapsed = now − restStartedAt` and re-arm. **This is correct whether or not timers
   freeze** — which is exactly what you want when the doc is silent.
5. **Make `onShow` idempotent.** Xiaomi warns about precisely this: it re-fires on every wrist-raise. No
   side effects beyond recomputing state from the clock.
6. **Persist after every single set.** Pages are documented as destroyable under stack pressure; memory is
   documented as tight; app-kill policy is undocumented. Cheap insurance.
7. **Evaluate `setKeepScreenOn(true)` as an explicit "workout mode"**, gated behind `canIUse` — perhaps only
   during an active rest countdown rather than for 90 minutes straight.
8. **Set-entry UI: vertical gestures and big targets.** Right-swipe is reserved for back. A ±stepper seeded
   from the previous set is likely the fewest interactions; `picker` is the best first-party fallback.
9. **Drop anything premised on heart rate or step count.** Those APIs do not exist.
10. **Set `minAPILevel` explicitly (4 is defensible)** and gate anything uncertain behind `canIUse`.

---

## Must be settled on hardware — the docs will not answer these

Ranked by how much they would reshape the design:

1. **Does `setInterval` keep firing with the screen off?** Log timestamps to storage, sleep the wrist 3 min,
   wake, inspect. *This is the central unknown.*
2. **After 3 min screen-off, does re-entry hit `onShow` or `onCreate`?** Instrument all five app hooks and
   all page hooks with timestamped storage writes.
3. **Does `setKeepScreenOn(true)` work on Band 10 at all**, and does it survive a wrist-drop?
4. **What does starting a Mi Fitness workout do to our app?** Completely undocumented.
5. **Does `@system.interconnect` work on Band 10?** No support table exists. (Ticket
   [#4](https://github.com/alikulovuzz/gym_log/issues/4).)
6. **Does data survive a band reboot?** No flush primitive, no durability guarantee.
7. **What is the actual storage ceiling?** Use `device.getAvailableStorage()` on-device.
8. **Is `config.background` honoured for a sideloaded third-party `.rpk` at all?**

[specs]: https://www.mi.com/global/product/xiaomi-smart-band-10/specs/
[multiscreen]: https://iot.mi.com/vela/quickapp/en/guide/design/multi-screens.html
[layout]: https://iot.mi.com/vela/quickapp/en/guide/framework/style/page-style-and-layout.html
[manifest]: https://iot.mi.com/vela/quickapp/en/guide/framework/manifest.html
[device]: https://iot.mi.com/vela/quickapp/en/features/basic/device.html
[calc]: https://github.com/open-vela/packages_apps/tree/dev/wearable/multi-screen-calculator
[events]: https://iot.mi.com/vela/quickapp/en/components/general/events.html
[components]: https://iot.mi.com/vela/quickapp/en/components/
[picker]: https://iot.mi.com/vela/quickapp/en/components/form/picker.html
[slider]: https://iot.mi.com/vela/quickapp/en/components/form/slider.html
[swiper]: https://iot.mi.com/vela/quickapp/en/components/container/swiper.html
[scroll]: https://iot.mi.com/vela/quickapp/en/components/container/scroll.html
[input]: https://iot.mi.com/vela/quickapp/en/components/form/input.html
[prompt]: https://iot.mi.com/vela/quickapp/en/features/other/prompt.html
[ime]: https://github.com/NEORUAA/Vela_input_method
[extensions]: https://iot.mi.com/vela/quickapp/en/guide/developer-materials/extension-components.html
[record]: https://iot.mi.com/vela/quickapp/en/features/system/record.html
[features]: https://iot.mi.com/vela/quickapp/en/features/
[storage]: https://iot.mi.com/vela/quickapp/en/features/data/storage.html
[file]: https://iot.mi.com/vela/quickapp/en/features/data/file.html
[structure]: https://iot.mi.com/vela/quickapp/en/guide/framework/project-structure.html
[acceptance]: https://iot.mi.com/vela/quickapp/en/guide/publish/acceptance-criteria.html
[memory]: https://iot.mi.com/vela/quickapp/en/guide/best-practice/memory.html
[tips]: https://iot.mi.com/vela/quickapp/en/guide/other/tips.html
[tipszh]: https://iot.mi.com/vela/quickapp/zh/guide/other/tips.html
[lifecycle]: https://iot.mi.com/vela/quickapp/en/guide/framework/script/lifecycle.html
[background]: https://iot.mi.com/vela/quickapp/en/guide/framework/other/background-running.html
[brightness]: https://iot.mi.com/vela/quickapp/en/features/system/brightness.html
[app]: https://iot.mi.com/vela/quickapp/en/features/basic/app.html
[globals]: https://iot.mi.com/vela/quickapp/en/guide/framework/script/global-data-method.html
[start]: https://iot.mi.com/vela/quickapp/en/guide/best-practice/start.html
[launchmode]: https://iot.mi.com/vela/quickapp/en/guide/framework/other/launch-mode.html
[vibrator]: https://iot.mi.com/vela/quickapp/en/features/system/vibrator.html
[sensor]: https://iot.mi.com/vela/quickapp/en/features/system/sensor.html
[battery]: https://iot.mi.com/vela/quickapp/en/features/system/battery.html
[event]: https://iot.mi.com/vela/quickapp/en/features/system/event.html
[version]: https://iot.mi.com/vela/quickapp/en/guide/version/
[fetch]: https://iot.mi.com/vela/quickapp/en/features/network/fetch.html
[network]: https://iot.mi.com/vela/quickapp/en/features/system/network.html
[bluetooth]: https://iot.mi.com/vela/quickapp/en/features/system/bluetooth.html
[interconnect]: https://iot.mi.com/vela/quickapp/en/features/network/interconnect.html
