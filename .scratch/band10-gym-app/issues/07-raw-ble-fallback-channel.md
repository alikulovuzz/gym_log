# Fallback sync channel: can a Vela app speak raw BLE to our Android app?

Type: research
Status: open
Blocked by: 03

## Question

If `@system.interconnect` turns out to be locked to Mi Fitness, is there another way off the wrist?

The Vela **System Capabilities** section lists a **bluetooth** API alongside sensors, vibration and battery. If a quick app can open its own BLE connection — acting as central or peripheral, exposing or consuming a GATT service — then the band can talk directly to our Android app and `interconnect` becomes irrelevant.

Settle:

- What does the Vela bluetooth API actually permit — scanning, connecting as central, advertising as peripheral, custom GATT services? Or only a narrow "read the paired device" surface?
- **The coexistence question, which is the crux:** the band's Bluetooth radio is already occupied by its pairing with Mi Fitness. Can an app open a *second*, independent BLE link while that pairing is live — or does the platform own the radio exclusively? A BLE API that only works when the band is unpaired is useless for a device you wear all day.
- Range and reconnection behaviour: if the phone is in a locker on the other side of the gym, what happens — and what happens when it comes back?
- Battery cost of holding a BLE link through a workout.

## Notes

AFK research. Blocked by ticket 03 because if `interconnect` is open to third-party apps, this whole line of enquiry is unnecessary and should be closed unworked — spending a session on a fallback we don't need is exactly the waste the map exists to prevent.

If 03 comes back **closed** (interconnect is Mi-Fitness-only), this ticket becomes the critical path to the destination, and its failure would mean the "automatically send to phone" half of the destination is unreachable — which would be grounds to redraw the destination, not to quietly drop it.
