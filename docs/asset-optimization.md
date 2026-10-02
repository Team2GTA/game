# Asset optimization

Sizes are MiB (1,048,576 bytes).

| Content | Before | After |
| --- | ---: | ---: |
| Source assets | 561.0 | 142.8 |
| Imported asset cache | 1067.2 | 218.3 |
| Validated Windows game-data pack | Not measured | 112.3 |

The pack measurement excludes the Godot executable. No before/after export-size claim is made.

## Changes

- Archived unused source assets after checking both scene/script paths and Godot resource dependencies, including UID references. Existing standalone scenes were preserved.
- Removed unused 8K knife textures rather than reducing textures used by the game. Active textures retain their original pixels and resolution.
- Replaced embedded textures in `pot_1.glb` and `torch.glb` with pixel-identical existing external textures. The models now occupy approximately 265 KiB and 227 KiB. Geometry and material data were verified against the originals.
- Removed three duplicate pot textures and stale import-cache variants.
- Archived the gameplay recording outside the project.
- Retained the Windows application icon, the shader open in the editor, and the pre-existing custom flare-gun import edit.
- Set every export preset to selected game resources and their dependencies, explicitly including script-loaded scenes and global class scripts. Tests, maintenance tools, recordings, and ZIP archives are excluded.

## Future exports

After adding scenes, scripts, or resources referenced by scripts, run:

```powershell
python tools/refresh_export_resources.py
```

Use Godot's Resources export tab to add resources loaded through dynamically constructed paths; the refresh tool discovers literal paths only. Keep original authoring assets outside the game project when the editable Godot scene already contains their geometry.

## Recovery

Original assets, import sidecars, export settings, and the recording were backed up and SHA-256 verified before removal:

`C:\Users\chekm\.codex\visualizations\2026\09\25\01a0d8a6-bf87-7151-91eb-97d5237974b2\Bonk-original-assets.zip`

The ZIP contains original project-relative paths and `backup-manifest.json`. Extract specific files back to their original paths to restore them. It remains outside the project and is not included in exports. Keeping the backup still uses disk space.

## Validation

- 26 source-project regression checks passed after cleanup and reimport.
- 24 gameplay checks passed against the exported pack from an empty directory, without source-tree fallback.
- The two rewritten models retain byte-identical geometry data and pixel-identical decoded textures.
- The headless environment reports certificate-store and dummy-renderer messages; editor import/export also reports inability to save global editor settings within the sandbox. The final exported game has no missing-resource or script errors in the tested gameplay paths.
