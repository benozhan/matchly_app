"""
Adds Amerika/ABD aliases to ALIASES dict in /opt/KuponBot/api_server.py.
Run on VPS:
  python3 /opt/KuponBot/patch_aliases_minimal.py
"""

import pathlib, sys

TARGET = pathlib.Path("/opt/KuponBot/api_server.py")
src = TARGET.read_text(encoding="utf-8")

# Insert after the "turkey" line which already exists
OLD = '"turkey":           ["turkey", "türkiye", "turkiye"],'
NEW = '''"turkey":           ["turkey", "türkiye", "turkiye"],
    "united states":    ["united states", "usa"],
    "usa":              ["united states", "usa"],
    "amerika":          ["united states", "usa"],
    "abd":              ["united states", "usa"],
    "amerika birleşik devletleri": ["united states", "usa"],'''

if OLD not in src:
    sys.exit("ERROR: anchor line not found. Check ALIASES dict manually.")

if '"amerika"' in src:
    sys.exit("Already patched — 'amerika' key exists.")

patched = src.replace(OLD, NEW, 1)
TARGET.write_text(patched, encoding="utf-8")
print("Patched OK.")
print("Test: python3 -c \"import api_server; print(api_server.expand_query('amerika'))\"")
print("Restart: systemctl restart matchly-api")
