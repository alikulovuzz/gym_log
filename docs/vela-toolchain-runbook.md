# Vela toolchain runbook (Windows)

Working setup for building a Vela quick app (`.rpk`) for the Xiaomi Smart Band 10.
Produced while resolving [#3](https://github.com/alikulovuzz/gym_log/issues/3).

## Verified environment

| | |
|---|---|
| OS | Windows 11 Pro (26200), x64 |
| Node | v24.14.0 |
| npm | 11.16.0 |
| `aiot-toolkit` | 2.0.5 |
| `@aiot-toolkit/jsc` | 1.0.3 |

**Windows is fully supported.** No native build steps, no virtualisation prerequisite for
`aiot build`, no Linux/macOS-only escape hatch. `npm install` pulled 718 packages and exited
clean; the toolkit even handles Windows explicitly (it creates `node_modules` junctions rather
than symlinks, and the emulator downloader resolves a `windows-x86_64` artifact).

## Project layout

The project is `band-app/`. It was produced from the toolkit's own `vela-demo` template — the
same output `npm create aiot` gives you, materialised directly because `npx create-aiot` is an
interactive prompt-driven scaffolder.

```
band-app/
  package.json          # devDeps: aiot-toolkit, @aiot-toolkit/jsc
  src/
    manifest.json       # package id, features, router, deviceTypeList
    config-watch.json   # per-deviceType overrides, merged into manifest-<type>.json
    app.ux
    pages/index/index.ux
    pages/detail/detail.ux
    common/logo.png
    i18n/
  build/                # intermediate compile output (gitignored)
  dist/                 # the .rpk lands here (gitignored)
```

## Commands

```bash
cd band-app
npm install

npx aiot build      # development mode -> dist/<package>.debug.<version>.rpk
npx aiot release    # production mode  -> requires your own signing keys (see below)
npx aiot start      # build + boot emulator + install + run

npx aiot initEmulatorEnv   # download the emulator SDK (~750 MB, one-off)
npx aiot createVVD         # create a Vela Virtual Device (interactive)
npx aiot resign            # re-sign build/ into dist/ without recompiling
```

Build is fast: **316 ms** for the hello-world, producing a 16,993-byte `.rpk`.

## Signing — the important part

Every `.rpk` is signed. There is no unsigned build path. Which key gets used depends on mode:

- **`aiot build` (development)** falls back through `sign/debug/*.pem` → `sign/*.pem` → **a
  default keypair bundled inside `@aiot-toolkit/aiotpack`**. A fresh project with no `sign/`
  directory still builds and still signs, using Xiaomi's shipped development key. Zero config.
- **`aiot release` (production)** looks only at `sign/release/*.pem` → `sign/*.pem`. There is
  **no fallback** — with neither present it throws
  `The current mode is production, and there is a problem with the certification path`.

Crucially, release signing wants a keypair *you generate yourself*. No Xiaomi-issued
certificate, no CA, no review process is involved in producing a signed `.rpk`.

The signature is a custom **`RPK Sig Block 42`** block spliced between the ZIP local file
headers and the central directory — deliberately modelled on Android's APK Signing Block
(`APK Sig Block 42`). It carries SHA-256 digests of the header/central/EOCD chunks, an RSA
signature, the public key, the DER certificate, and a per-file digest block.

**This is the seed of [#7](https://github.com/alikulovuzz/gym_log/issues/7).** The open
question there is not *can we sign* — we can, trivially — but *whose signature the band's
installer will accept*: the bundled default dev cert, a self-generated release cert, or only
something Xiaomi-trusted.

## Emulator

The emulator is **the Android emulator (QEMU) with Xiaomi wearable skins** — AVD config files,
`emulator_controller.proto`, `adb`. It is not shipped in the npm package; `initEmulatorEnv`
downloads it from Xiaomi's CDN.

| Part | Size |
|---|---|
| emulator (`windows-x86_64`) | 333 MB |
| system image `vela-miwear-watch-5.0` | 383 MB |
| `qa` | 28 MB |
| skins | 0.9 MB |
| **total** | **~750 MB** |

All artifacts are served from `https://vela-ide.cnbj3-fusion.mi-fds.com/vela-ide` and were
**reachable from here without a VPN** (all HTTP 200) — worth stating, since the rest of the
Vela ecosystem is China-hosted.

### There IS a Band-10-shaped device profile

The skins bundle ships `xiaomi_band_10`:

```
display  212 x 520
shape    pill-shaped
density  320
flavor   band
```

212×520 is the Band 10's real panel resolution, and the skin includes bezel artwork. Sibling
skins: `xiaomi_band` (192×490), `xiaomi_band_pro` (336×480), `xiaomi_watch` (466×466),
`redmi_watch` (432×514), `xiaomi_sound_mini` (800×480).

So the "developing a band UI against a watch-sized emulator" trap the ticket warned about
**does not apply** — provided you select the `xiaomi_band_10` skin at `createVVD` time. The
*default* AVD really is a 466×466 watch, so this is opt-in and easy to get wrong.

### Gotcha: which image lets you pick a skin

`createVVD` prompts in this order: name → image → skin/size. The skin prompt only appears for
**miwear** image types (`vela-miwear-watch-5.0`, `vela-release-4.0`). Choosing a non-miwear
image (`vela-watch-5.0`) silently locks you to 466×466 with no prompt at all — which directly
contradicts that image's own description ("可自定义模拟器尺寸" / "emulator size is
customisable"). The descriptions and the code disagree; trust the code.

**To get a Band 10 emulator: choose `vela-miwear-watch-5.0`, answer yes to "need vvd skin?",
then pick `xiaomi_band_10`.**

### Gotcha: ARM guest

The AVD is `armeabi-v7a` / `hw.cpu.arch = arm` with `hw.gpu.enabled = no`, and the host process
is literally `qemu-system-armel`. On an x86_64 Windows host that means QEMU software
translation — emulation, not virtualisation. In practice it was fine: cold boot to
`Vela_Band10 started successfully` took **~10 seconds**.

### Open gotcha: the panel renders black

The app installs, launches and reaches `Page ready` — but the emulator's device panel paints
**black**. The window (a shaped, transparent skin window) shows the pill bezel correctly; the
212×520 display area inside it stays blank.

Evidence it is a *rendering* problem, not an app problem:

- `quickapp_state_trans: [launching] -> [toFG] -> [forground]`, then
  `Page ready page_info:name:pages/index` and `DomComponent doMapWidget ready`.
- No JS errors of any kind in the log.
- The guest logs `miwear_fb_anim_draw_start: miwear fb draw fail` and
  `startup_anim_callback: startup anim draw fail` during boot — the framebuffer is failing to
  draw before our app even starts.
- Relaunching with `-gpu swiftshader_indirect` did not clear it.

Not yet ruled out: the band simply blanking its screen on idle (`MiWearScreen` reports
`keepon_enabled:false`, and it does log `screen_user_activity` when the app is started).

**This is unresolved and it blocks any visual UI work** — see
[Make the Vela emulator actually render the app's UI](https://github.com/alikulovuzz/gym_log/issues/13).

### Gotcha: installs do not survive a cold boot

After killing the emulator and cold-booting it again (`-no-snapshot`), the previously installed
package was gone from `/data/app`. Re-running `aiot start` re-pushes and re-installs each time,
so this never bites during normal development — but do not treat emulator state as durable.

### adb: it is NuttX, not Android

`adb` is only the transport. The guest is **NuttX** with an `nsh` shell, so Android shell tools
are absent — `screencap` does not exist, and `ls` takes different arguments. `adb push`,
`adb shell pm install` and `adb shell am start` do work; that is the whole install path.

The `adb` binary is not in the downloaded SDK — it ships inside the npm dependency at
`node_modules/@miwt/adb/bin/win/adb.exe`.

## Other notes

- `manifest.json` declares `deviceTypeList: ["watch"]`; the build merges
  `config-<deviceType>.json` over `manifest.json` to emit `manifest-<deviceType>.json` into the
  `.rpk`. "watch" is the device type that covers bands.
- The build errors if your code uses a `@system.*` feature not declared in `manifest.features`.
  `--complete-feature` auto-fills them instead of failing. Expect to hit this the moment we
  touch `@system.interconnect`.
- `npm install` leaves two install scripts unrun under npm's `allow-scripts` gate
  (`protobufjs`, `@parcel/watcher`). `aiot build` works fine without them. `@parcel/watcher`
  backs `--watch`, so approve it if `aiot start --watch` misbehaves.
- The toolkit builds via a temporary sibling project (`.temp_band-app/`) and moves `build/` and
  `dist/` back on success. Harmless, but it will litter the parent directory if a build dies
  midway.
