# Get the Vela toolchain building an .rpk and running in the emulator

Type: task
Status: open
Blocked by: —

## Question

Can we go from an empty directory to a built `.rpk` and a running app in the Vela emulator, on this Windows machine?

Per the official docs (https://iot.mi.com/vela/quickapp/en/tools/toolkit/start.html): `npm create aiot` scaffolds, `aiot start` runs the emulator, `aiot build` produces the `.rpk`, `aiot release` builds in release mode. `aiot getConnectedDevices` / `aiot getPlatforms` exist for device management.

Settle:

- Does AIoT-toolkit 2.0 install and run on **Windows**? (Docs are thin on prerequisites — Node version, native deps, whether the emulator needs virtualisation enabled.) If it is Linux/macOS-only in practice, say so loudly: it changes the shape of every build ticket after this.
- Does the emulator have a **Band-10-shaped device profile** (correct screen geometry), or only watches? Developing a band UI against a watch-sized emulator would be a slow, silent trap.
- Build the scaffolded hello-world and confirm a `.rpk` file lands on disk.
- Note whether `aiot build` output is **signed**, and whether release vs debug mode changes that — this is the seed of ticket 06.

This runs entirely on the dev machine, no band required, so it can proceed in parallel with the hardware test.

## Notes

AFK. The agent can do this alone.

The answer should record the working setup as a short runbook (versions, commands, gotchas) plus the path to the built `.rpk` — which becomes the artifact that ticket 06 tries to sideload.
