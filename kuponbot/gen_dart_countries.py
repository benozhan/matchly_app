"""
Generates the _trTeam() Dart helper from country_names.py.

Run from kuponbot/ directory:
  python3 gen_dart_countries.py

Paste the output into add_coupon_sheet.dart, replacing the existing _trTeam() function.
"""
import sys
sys.path.insert(0, ".")
from country_names import EN_TO_TR

lines = [
    "// ─── Team / country name localisation ───────────────────────────────────────",
    "// AUTO-GENERATED from kuponbot/country_names.py — do not edit by hand.",
    "// To update: run  python3 kuponbot/gen_dart_countries.py  and paste the output.",
    "",
    "String _trTeam(String raw) {",
    "  const map = <String, String>{",
]

for en, tr in EN_TO_TR.items():
    en_esc = en.replace("'", "\\'")
    tr_esc = tr.replace("'", "\\'")
    lines.append(f"    '{en_esc.lower()}': '{tr_esc}',")

lines += [
    "  };",
    "  return map[raw.toLowerCase()] ?? raw;",
    "}",
]

print("\n".join(lines))
