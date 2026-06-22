"""
Patches normalize() and expand_query() in /opt/KuponBot/api_server.py.

Changes:
  - normalize() folds Turkish diacritics (ü→u ö→o ı→i ş→s ç→c ğ→g) + handles İ
  - expand_query() supports prefix matching: "fran" matches "fransa", "turk" matches "turkiye"

Run on VPS:
  python3 /opt/KuponBot/patch_normalize_prefix.py
"""

import pathlib, sys

TARGET = pathlib.Path("/opt/KuponBot/api_server.py")
src = TARGET.read_text(encoding="utf-8")

# ── 1. normalize() ────────────────────────────────────────────────────────────

OLD_NORMALIZE = '''\
def normalize(s: str) -> str:
    return " ".join(s.lower().strip().split())'''

NEW_NORMALIZE = '''\
# Fold Turkish diacritics to ASCII after lowercasing.
# ü→u  ö→o  ı→i  ş→s  ç→c  ğ→g
_TR_MAP = str.maketrans("üöışçğ", "uoiscg")

def normalize(s: str) -> str:
    """Lowercase, fold Turkish diacritics to ASCII, collapse whitespace."""
    # Replace İ (U+0130) before lower() — Python lower() yields 'i\\u0307' not 'i'
    s = s.replace("İ", "i")
    return " ".join(s.lower().translate(_TR_MAP).strip().split())'''

# ── 2. expand_query() ─────────────────────────────────────────────────────────

OLD_EXPAND = '''\
def expand_query(q: str) -> list[str]:
    """Return all DB search terms for a user query."""
    key = normalize(q)
    return ALIASES.get(key, [key])'''

NEW_EXPAND = '''\
def expand_query(q: str) -> list[str]:
    """Return all DB search terms for a user query.

    Matching rules:
    1. Exact:  key == alias_key
    2. Prefix: key starts with alias_key  (e.g. "fransa" triggers alias "fran"... N/A here)
    3. Prefix: alias_key starts with key  (e.g. "fran" triggers alias "fransa")
    All matched alias lists are merged and deduplicated.
    Falls back to [key] when no alias matches (triggers SQL LIKE %key%).
    """
    key = normalize(q)
    seen: dict[str, None] = {}  # ordered-set via insertion-ordered dict

    for alias_key, terms in ALIASES.items():
        nk = normalize(alias_key)
        if key == nk or key.startswith(nk) or nk.startswith(key):
            for t in terms:
                seen[t] = None

    return list(seen) if seen else [key]'''

# ── Apply ─────────────────────────────────────────────────────────────────────

if OLD_NORMALIZE not in src:
    sys.exit("ERROR: original normalize() not found — already patched or changed.")
if OLD_EXPAND not in src:
    sys.exit("ERROR: original expand_query() not found — already patched or changed.")

patched = src.replace(OLD_NORMALIZE, NEW_NORMALIZE, 1)
patched = patched.replace(OLD_EXPAND, NEW_EXPAND, 1)
TARGET.write_text(patched, encoding="utf-8")
print("normalize() and expand_query() patched OK.")
print()
print("Quick verify:")
print("  python3 -c \"")
print("  import os; os.environ['KUPONBOT_DB']='/opt/KuponBot/matches.db'")
print("  import sys; sys.path.insert(0,'/opt/KuponBot')")
print("  from api_server import expand_query")
print("  print(expand_query('fran'))    # -> ['france', 'fransa']")
print("  print(expand_query('amer'))    # -> ['united states', 'usa']")
print("  print(expand_query('turk'))    # -> ['turkey', 'türkiye', 'turkiye']")
print("  print(expand_query('alm'))     # -> ['germany', 'almanya']")
print("  print(expand_query('holl'))    # -> ['netherlands', 'hollanda']")
print("  \"")
print()
print("Restart: systemctl restart matchly-api")
