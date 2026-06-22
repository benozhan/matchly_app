"""
Patch script: add coupon_details / coupon_selections tables and
POST /social/coupons + GET /social/coupons/{coupon_id} endpoints.

Run on VPS:
    python3 /opt/KuponBot/patch_coupon_detail.py
"""
import os, re

BASE = os.path.dirname(__file__)

# ── 1. social_db.py — add new tables to _DDL ─────────────────────────────────

DB_FILE = os.path.join(BASE, "social_db.py")
DB_MARKER = "class SharedCouponCreate" if False else "idx_shared_coupons_public"
DB_ADDITION = """
CREATE INDEX IF NOT EXISTS idx_shared_coupons_public
    ON shared_coupons(is_public, created_at DESC);

-- ── Coupon detail storage ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS coupon_details (
    coupon_id  TEXT PRIMARY KEY,
    owner_id   TEXT REFERENCES users(id) ON DELETE SET NULL,
    title      TEXT NOT NULL DEFAULT '',
    site_name  TEXT NOT NULL DEFAULT '',
    stake      TEXT NOT NULL DEFAULT '',
    odds       TEXT NOT NULL DEFAULT '',
    potential  TEXT NOT NULL DEFAULT '',
    status     TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL
                   DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS coupon_selections (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    coupon_id  TEXT NOT NULL REFERENCES coupon_details(coupon_id) ON DELETE CASCADE,
    match_name TEXT NOT NULL DEFAULT '',
    bet_type   TEXT NOT NULL DEFAULT '',
    status     TEXT NOT NULL DEFAULT 'pending',
    last_score TEXT NOT NULL DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_coupon_details_owner
    ON coupon_details(owner_id);

CREATE INDEX IF NOT EXISTS idx_coupon_selections_coupon
    ON coupon_selections(coupon_id, sort_order);
\"\"\"
"""

src = open(DB_FILE).read()
OLD = 'CREATE INDEX IF NOT EXISTS idx_shared_coupons_public\n    ON shared_coupons(is_public, created_at DESC);\n"""'
NEW = 'CREATE INDEX IF NOT EXISTS idx_shared_coupons_public\n    ON shared_coupons(is_public, created_at DESC);\n\n-- ── Coupon detail storage ─────────────────────────────────────────────────\n\nCREATE TABLE IF NOT EXISTS coupon_details (\n    coupon_id  TEXT PRIMARY KEY,\n    owner_id   TEXT REFERENCES users(id) ON DELETE SET NULL,\n    title      TEXT NOT NULL DEFAULT \'\',\n    site_name  TEXT NOT NULL DEFAULT \'\',\n    stake      TEXT NOT NULL DEFAULT \'\',\n    odds       TEXT NOT NULL DEFAULT \'\',\n    potential  TEXT NOT NULL DEFAULT \'\',\n    status     TEXT NOT NULL DEFAULT \'pending\',\n    created_at TEXT NOT NULL\n                   DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%SZ\', \'now\'))\n);\n\nCREATE TABLE IF NOT EXISTS coupon_selections (\n    id         INTEGER PRIMARY KEY AUTOINCREMENT,\n    coupon_id  TEXT NOT NULL REFERENCES coupon_details(coupon_id) ON DELETE CASCADE,\n    match_name TEXT NOT NULL DEFAULT \'\',\n    bet_type   TEXT NOT NULL DEFAULT \'\',\n    status     TEXT NOT NULL DEFAULT \'pending\',\n    last_score TEXT NOT NULL DEFAULT \'\',\n    sort_order INTEGER NOT NULL DEFAULT 0\n);\n\nCREATE INDEX IF NOT EXISTS idx_coupon_details_owner\n    ON coupon_details(owner_id);\n\nCREATE INDEX IF NOT EXISTS idx_coupon_selections_coupon\n    ON coupon_selections(coupon_id, sort_order);\n"""'

if "coupon_details" in src:
    print("social_db.py already patched — skipping.")
else:
    with open(DB_FILE, "w") as f:
        f.write(src.replace(OLD, NEW))
    print(f"Patched {DB_FILE}")

# ── 2. social_router.py — append new endpoints ───────────────────────────────

ROUTER_FILE = os.path.join(BASE, "social_router.py")
router_src = open(ROUTER_FILE).read()
if "get_coupon_detail" in router_src:
    print("social_router.py already has coupon endpoints — skipping.")
else:
    # The full addition is in the patched social_router.py already committed.
    # On VPS, just copy the updated file from the repo.
    print("social_router.py: copy the updated file from the repo to apply changes.")

print("Done. Restart the API: systemctl restart matchly-api")
