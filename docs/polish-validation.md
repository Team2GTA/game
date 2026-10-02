# GigaBonk polish validation

Validated on 2026-09-25 with Godot 4.7.1 on Windows.

## Delivered

Dark arcade menus and anchored HUD; keyboard/mouse rebinding and reset; saved comfort settings, FOV and best score; deliberate movement/stamina; explicit rifle/axe action states; centralized pause-aware feedback; safe navigation-based spawning; consistent two-level, three-wave progression.

## Automated checks

| Suite | Source project | Fresh standalone pack |
| --- | --- | --- |
| Existing regression checks | 26 passed | 26 passed |
| New polish checks | 46 passed | 46 passed |
| Total | 72 passed, 0 failures | 72 passed, 0 failures |

Coverage includes weapon locks, reload reserve accounting, empty-fire behavior, single-hit melee, jump timing, stamina exhaustion/recovery, zoom reset, shake preference, paused feedback/countdowns, controls/reset, saved FOV/records, hidden-HUD reward guidance, navigation spawn constraints/retry, restart, defeat and victory. Pack tests ran from an empty directory against a newly exported PCK, with external test scripts and isolated settings. No gameplay scripts were loaded from the source project for those pack runs.

## Rendered verification

Captured 18 actual Forward+ rendered images: Start, Controls, gameplay, Pause, Defeat and Victory at 1280×720, 1920×1080 and 2560×1080. Inspected representative menus and gameplay across all three resolutions. Fixed clipped controls, character encoding, pause action emphasis, and the countdown remaining hidden after resume.

Reproduce with `godot --path . --script tools/capture_polish.gd`. Capture output: `.godot/polish/`. Delivered copies are outside the project in the task artifact folder, keeping screenshots out of game exports.

## Size and export

- Fresh exported pack: **117,765,392 bytes (112.31 MiB)**, excluding the engine executable.
- Active source assets: **142.85 MiB**.
- Active texture resolution unchanged; no new large art or audio assets.
- Feedback tones are short generated audio streams cached in memory.
- Export resource lists refreshed to include added scripts and their dependencies.

## Environment notes

No script failures were reported. The sandbox produced certificate-store and editor/shader-cache access warnings; headless teardown also reports a dummy-renderer material warning. These did not prevent rendering, export, or the successful checks above. Automated gameplay and rendered inspection do not constitute a prolonged human balance playtest.
