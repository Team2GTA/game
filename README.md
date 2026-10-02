# GigaBonk

A Godot 4.7 first-person wave survival game. Open `project.godot` and run the main scene.

## Progression and controls

Survive three waves per level, then collect the highlighted reward to continue. Level 2 reuses the existing arena with higher difficulty; completing its third wave wins. Total score persists throughout the run, while wave progress resets.

Use WASD to move, Shift to sprint, Space to jump, left mouse to attack, right mouse to zoom, R to reload, 1/2 to switch weapons, E to interact/place traps, and Escape to pause. Change bindings from Controls. Escape cancels a pending remap.

The dark arcade menu includes saved sensitivity, master volume, camera shake, head bob, HUD visibility, and a 65–95 degree field of view (default 75). Controls supports keyboard/mouse rebinding and Restore Defaults. Defeat and victory show the run score, highest wave, and saved best score. Preferences and bindings are stored in Godot's `user://settings.cfg`; restarting a run preserves them.

## Regression checks

With Godot available on your PATH:

```powershell
godot --headless --path . --script tests/regression.gd
godot --headless --path . --script tests/polish_regression.gd
```

Checks cover pause/resume, frozen wave timers, reward guidance, both levels, persistent score, victory, swept bullet collisions and damage, skeleton movement, cached hit flashes, and settings persistence. Tests use isolated settings under `.godot`, not player preferences.

The original 26 checks and 46 polish checks pass in both source and a standalone exported pack. Rendered menus and gameplay were inspected at 1280×720, 1920×1080, and 2560×1080. See [the polish validation report](docs/polish-validation.md). Regenerate screenshots with `godot --path . --script tools/capture_polish.gd`; images are written to `.godot/polish/`. Level 2 uses the same arena.

## Combat tuning

Walking remains 5.5 m/s; sprinting is 8 m/s. Stamina caps at 50, drains at 12/s while sprinting, and recovers at 9/s after 1.25 seconds. Exhaustion prevents sprinting until 15 stamina. Jumps cost 8, with a 100 ms input buffer and 80 ms ledge grace period.

The rifle fires every 0.24 seconds and reloads in 1.8 seconds. The axe swings over 0.55 seconds with one hit per swing. Weapon actions lock switching, changing weapons resets zoom, and camera bob, recoil, and damage shake remain independent. The HUD provides hit/kill confirmation, pickup notices, reload progress, and bound-key interaction prompts.

## Asset size and export maintenance

Unused originals are archived outside the project; active textures keep their original quality. See [the optimization report](docs/asset-optimization.md) for sizes, validation, and the recovery archive.

Run `python tools/refresh_export_resources.py` after adding script-loaded resources so all export presets include their dependencies.
