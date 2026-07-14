# Map the Band 10's constraints for a gym app

Type: research
Status: open
Blocked by: —

## Question

What does the Band 10 actually give an app to work with, and what will it refuse?

The gym app's whole design — how a set gets entered, how much history lives on the wrist, whether a workout can span an hour — is downstream of these limits. Establish them from the docs before designing against imagined ones.

- **Screen and input.** Exact resolution and physical size of the Band 10 display. What input primitives do the Vela UI components offer — tap, swipe, long-press, scroll, a rotating/side button, any picker or stepper component? Is there a text-input component at all, and is it usable? (Realistically, entering "85 kg × 5" must be done without a keyboard.)
- **Storage.** `@system.storage` vs file storage: quota per app, persistence guarantees, whether data survives app restart, band reboot, and app update. How many sessions of gym history can plausibly live on the wrist.
- **Lifecycle.** Can an app keep running with the screen off? Is there a background-execution or "background process" model (the docs mention one under Advanced Features)? What kills an app — timeout, another app opening, a workout started in Mi Fitness? If the band suspends our app between sets, the entire UX changes.
- **Sensors and haptics.** Vibration (for a rest timer), heart rate, battery level.
- **API level.** The docs version APIs by "API level" — determine which level Band 10's firmware exposes, so we don't design against APIs it doesn't have.

## Notes

AFK research against https://iot.mi.com/vela/quickapp/en/ (features, components, and version-notes sections). Produce a markdown summary as a linked asset.

The **lifecycle** finding is the one most likely to surprise us and most likely to reshape the design. Give it real attention rather than a sentence.
