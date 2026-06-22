"""
Social feature — SQLite schema and low-level DB helpers.

Tables created here are intentionally minimal for V1.
Reserved for future extension: comments, likes, notifications, leaderboards.
"""

from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from typing import Generator

SOCIAL_DB_PATH = os.environ.get("SOCIAL_DB", "social.db")

# ── Schema ────────────────────────────────────────────────────────────────────

_DDL = """
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id           TEXT PRIMARY KEY
                     DEFAULT (lower(hex(randomblob(8)))),
    username     TEXT UNIQUE NOT NULL COLLATE NOCASE,
    display_name TEXT NOT NULL,
    avatar       TEXT,
    created_at   TEXT NOT NULL
                     DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE TABLE IF NOT EXISTS follows (
    follower_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TEXT NOT NULL
                     DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE TABLE IF NOT EXISTS shared_coupons (
    id         TEXT PRIMARY KEY
                   DEFAULT (lower(hex(randomblob(8)))),
    coupon_id  TEXT NOT NULL,
    owner_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_public  INTEGER NOT NULL DEFAULT 1 CHECK (is_public IN (0, 1)),
    created_at TEXT NOT NULL
                   DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- ── Indexes (for future leaderboard / feed / notification queries) ─────────

CREATE INDEX IF NOT EXISTS idx_follows_follower
    ON follows(follower_id);

CREATE INDEX IF NOT EXISTS idx_follows_following
    ON follows(following_id);

CREATE INDEX IF NOT EXISTS idx_shared_coupons_owner
    ON shared_coupons(owner_id, created_at DESC);

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
"""


def init_db() -> None:
    """Create tables and indexes. Safe to call on every startup (idempotent)."""
    with sqlite3.connect(SOCIAL_DB_PATH) as conn:
        conn.executescript(_DDL)


# ── Connection helper ─────────────────────────────────────────────────────────

@contextmanager
def get_conn() -> Generator[sqlite3.Connection, None, None]:
    conn = sqlite3.connect(SOCIAL_DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
