"""
Replaces expand_query() in /opt/KuponBot/api_server.py with prefix-aware version.
Run on VPS:
  python3 /opt/KuponBot/patch_expand_query.py
"""

import pathlib, sys

TARGET = pathlib.Path("/opt/KuponBot/api_server.py")
src = TARGET.read_text(encoding="utf-8")

OLD = '''\
def expand_query(q: str) -> list[str]:
    """Return all DB search terms for a user query."""
    key = normalize(q)
    return ALIASES.get(key, [key])'''

NEW = '''\
def expand_query(q: str) -> list[str]:
    """Return all DB search terms for a user query.

    Matching rules (in order):
    1. Exact alias key match.
    2. Prefix match: query starts with an alias key (e.g. "fransa" → key "fransa").
    3. Prefix match: alias key starts with query (e.g. "fran" → key "fransa").
    All matched alias lists are merged and deduplicated.
    Falls back to [query] if no alias matches.
    """
    key = normalize(q)
    seen: dict[str, None] = {}  # ordered set via insertion-ordered dict

    for alias_key, terms in ALIASES.items():
        if key == alias_key or key.startswith(alias_key) or alias_key.startswith(key):
            for t in terms:
                seen[t] = None

    if seen:
        return list(seen)
    return [key]'''

if OLD not in src:
    sys.exit("ERROR: original expand_query block not found — check manually.")

patched = src.replace(OLD, NEW, 1)
TARGET.write_text(patched, encoding="utf-8")
print("expand_query patched OK.")

# Quick self-test using the patched file
import importlib.util, types
spec = importlib.util.spec_from_file_location("api_server", TARGET)
mod = importlib.util.load_from_spec = None  # skip full import (FastAPI dep)

# Manual smoke test on the raw source
exec(compile(patched, str(TARGET), "exec"), {"__builtins__": __builtins__,
     "lru_cache": __import__("functools").lru_cache,
     "Optional": __import__("typing").Optional})
# ALIASES and expand_query are now in local scope via exec — can't easily test here
# Just print instructions
print()
print("Verify on VPS:")
print("  python3 -c \"")
print("  import sys; sys.path.insert(0,'/opt/KuponBot')")
print("  # set DB_PATH before import")
print("  import os; os.environ['KUPONBOT_DB']='/opt/KuponBot/matches.db'")
print("  from api_server import expand_query")
print("  print(expand_query('fran'))     # -> france")
print("  print(expand_query('amer'))     # -> united states")
print("  print(expand_query('turk'))     # -> turkey/türkiye")
print("  \"")
print()
print("Restart: systemctl restart matchly-api")
