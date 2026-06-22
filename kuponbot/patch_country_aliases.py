"""
Patches api_server.py on the VPS to import country_names.py and
auto-build country aliases from it.

Run on VPS after copying both files:
  scp country_names.py patch_country_aliases.py user@vps:/opt/KuponBot/
  ssh user@vps "python3 /opt/KuponBot/patch_country_aliases.py && systemctl restart matchly-api"
"""

import pathlib, sys

TARGET = pathlib.Path("/opt/KuponBot/api_server.py")
src = TARGET.read_text(encoding="utf-8")

OLD = '''\
def expand_query(q: str) -> list[str]:'''

NEW = '''\
def _build_country_aliases() -> None:
    """Extend ALIASES with EN⇔TR country pairs from country_names.py.

    Called after normalize() is defined. Idempotent.
    Silently skips if country_names.py is not present.
    """
    try:
        from country_names import EN_TO_TR  # type: ignore
    except ImportError:
        return

    for en, tr in EN_TO_TR.items():
        en_low  = en.lower()
        tr_norm = normalize(tr)
        en_norm = normalize(en)

        # TR search term → EN DB variants (e.g. "almanya" → ["germany", "almanya"])
        if tr_norm not in ALIASES:
            ALIASES[tr_norm] = list(dict.fromkeys([en_low, en_norm, tr_norm]))

        # EN search term → EN DB variants passthrough
        if en_norm not in ALIASES:
            ALIASES[en_norm] = list(dict.fromkeys([en_low, en_norm]))


_build_country_aliases()


def expand_query(q: str) -> list[str]:'''

if OLD not in src:
    sys.exit("ERROR: anchor not found — already patched or file changed.")
if "_build_country_aliases" in src:
    sys.exit("Already patched.")

patched = src.replace(OLD, NEW, 1)
TARGET.write_text(patched, encoding="utf-8")
print("Patched OK.")
print()
print("Verify:")
print("  python3 -c \"")
print("  import os; os.environ['KUPONBOT_DB']='/opt/KuponBot/matches.db'")
print("  import sys; sys.path.insert(0,'/opt/KuponBot')")
print("  from api_server import expand_query, ALIASES")
print("  print(expand_query('uzbekistan'))   # -> ['uzbekistan']")
print("  print(expand_query('ozbekistan'))   # -> ['uzbekistan', ...]")
print("  print(expand_query('cezayir'))      # -> ['algeria', ...]")
print("  print(expand_query('hırvatistan'))  # -> ['croatia', ...]")
print("  \"")
print()
print("Restart: systemctl restart matchly-api")
