"""Refresh export roots, including scenes loaded by scripts and global classes."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
roots = {"res://scenes/Level/main.tscn", "res://icon.svg"}
for folder in ("scripts", "scenes"):
    for script in (ROOT / folder).rglob("*.gd"):
        roots.add("res://" + script.relative_to(ROOT).as_posix())
        roots.update(re.findall(r'"(res://[^"\n]+)"', script.read_text(encoding="utf-8")))
for resource in roots:
    if not (ROOT / resource.removeprefix("res://")).is_file():
        raise SystemExit("Missing export root: " + resource)
path = ROOT / "export_presets.cfg"
text = path.read_text(encoding="utf-8")
text = re.sub(r'^export_filter=.*$', 'export_filter="resources"', text, flags=re.M)
value = "export_files=PackedStringArray(" + ", ".join('"' + p + '"' for p in sorted(roots)) + ")"
text = re.sub(r'^export_files=.*$', value, text, flags=re.M)
text = re.sub(r'^exclude_filter=.*$', 'exclude_filter="tests/*,tools/*,*.mp4,*.zip"', text, flags=re.M)
path.write_text(text, encoding="utf-8", newline="\n")
print(f"Updated all export presets with {len(roots)} resource roots.")
