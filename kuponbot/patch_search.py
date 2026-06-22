"""
Minimal patch — fixes query search date filter in /opt/KuponBot/api_server.py.
Run on VPS:
  python3 /opt/KuponBot/patch_search.py
"""

import pathlib, sys

TARGET = pathlib.Path("/opt/KuponBot/api_server.py")
src = TARGET.read_text()

# ── Primary query SQL ─────────────────────────────────────────────────────────

OLD_QUERY = '''\
            try:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE {where}
                    ORDER BY {time_col} ASC
                    LIMIT 20
                    """,
                    params,
                ).fetchall()
            except sqlite3.OperationalError:
                rows = conn.execute(
                    f"SELECT * FROM matches WHERE {where} ORDER BY rowid ASC LIMIT 20",
                    params,
                ).fetchall()'''

NEW_QUERY = '''\
            try:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE ({where})
                      AND datetime({time_col}) >= datetime('now')
                    ORDER BY datetime({time_col}) ASC
                    LIMIT 20
                    """,
                    params,
                ).fetchall()
            except sqlite3.OperationalError:
                rows = conn.execute(
                    f"""
                    SELECT * FROM matches
                    WHERE ({where})
                      AND datetime({time_col}) >= datetime('now')
                    ORDER BY datetime({time_col}) ASC
                    LIMIT 20
                    """,
                    params,
                ).fetchall()'''

if OLD_QUERY not in src:
    sys.exit("ERROR: expected query block not found — check manually.")

patched = src.replace(OLD_QUERY, NEW_QUERY, 1)
TARGET.write_text(patched)
print("Patched OK.")
print("Restart: systemctl restart matchly-api")
print("Verify:  curl 'http://localhost:8001/api/matches/search?q=turkiye'")
