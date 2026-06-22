"""
Social feature — FastAPI router (V1).

Endpoints
─────────
POST   /social/users
GET    /social/users/{username}
POST   /social/follow
DELETE /social/follow
GET    /social/users/{username}/followers
GET    /social/users/{username}/following
GET    /social/users/{username}/shared-coupons
GET    /social/find-users?q=
GET    /social/feed/{username}
GET    /social/coupons/{coupon_id}   (bridges kupon_bot.db for real data)
POST   /social/coupons
POST   /social/shared-coupons
"""

from __future__ import annotations

import os
import sqlite3
import sys
from typing import Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from social_db import get_conn, init_db

# Path to the real KuponBot database — used as fallback for coupon details.
KUPONBOT_DB_PATH = os.environ.get("KUPONBOT_DB", "kupon_bot.db")

# Initialise tables on import (idempotent).
init_db()

router = APIRouter(prefix="/social", tags=["social"])

# ── Pydantic models ───────────────────────────────────────────────────────────


class UserCreate(BaseModel):
    username:    str = Field(..., min_length=3, max_length=30, pattern=r"^[A-Za-z0-9_]+$")
    displayName: str = Field(..., min_length=1, max_length=60)
    avatar:      Optional[str] = None


class User(BaseModel):
    id:             str
    username:       str
    displayName:    str
    avatar:         Optional[str]
    createdAt:      str
    followerCount:  int = 0
    followingCount: int = 0


class FollowRequest(BaseModel):
    followerId:  str
    followingId: str


class SharedCoupon(BaseModel):
    id:        str
    couponId:  str
    ownerId:   str
    isPublic:  bool
    createdAt: str


# ── Helpers ───────────────────────────────────────────────────────────────────

def _require_user_by_username(conn: sqlite3.Connection, username: str) -> sqlite3.Row:
    row = conn.execute(
        "SELECT * FROM users WHERE username = ? COLLATE NOCASE", (username,)
    ).fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail=f"User '{username}' not found")
    return row


def _row_to_user(row: sqlite3.Row, conn: sqlite3.Connection) -> User:
    uid = row["id"]
    follower_count  = conn.execute(
        "SELECT COUNT(*) FROM follows WHERE following_id = ?", (uid,)
    ).fetchone()[0]
    following_count = conn.execute(
        "SELECT COUNT(*) FROM follows WHERE follower_id = ?", (uid,)
    ).fetchone()[0]
    return User(
        id=uid,
        username=row["username"],
        displayName=row["display_name"],
        avatar=row["avatar"],
        createdAt=row["created_at"],
        followerCount=follower_count,
        followingCount=following_count,
    )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/users", response_model=User, status_code=status.HTTP_201_CREATED)
def create_user(body: UserCreate) -> User:
    with get_conn() as conn:
        try:
            conn.execute(
                "INSERT INTO users (username, display_name, avatar) VALUES (?, ?, ?)",
                (body.username, body.displayName, body.avatar),
            )
        except sqlite3.IntegrityError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Username '{body.username}' is already taken",
            )
        row = conn.execute(
            "SELECT * FROM users WHERE username = ?", (body.username,)
        ).fetchone()
        return _row_to_user(row, conn)


@router.get("/users/{username}", response_model=User)
def get_user(username: str) -> User:
    with get_conn() as conn:
        row = _require_user_by_username(conn, username)
        return _row_to_user(row, conn)


@router.post("/follow", status_code=status.HTTP_201_CREATED)
def follow(body: FollowRequest) -> dict:
    with get_conn() as conn:
        # Verify both users exist
        for uid, label in [(body.followerId, "follower"), (body.followingId, "following")]:
            if not conn.execute("SELECT 1 FROM users WHERE id = ?", (uid,)).fetchone():
                raise HTTPException(status_code=404, detail=f"{label} user not found")
        if body.followerId == body.followingId:
            raise HTTPException(status_code=400, detail="Cannot follow yourself")
        try:
            conn.execute(
                "INSERT INTO follows (follower_id, following_id) VALUES (?, ?)",
                (body.followerId, body.followingId),
            )
        except sqlite3.IntegrityError:
            pass  # Already following — idempotent
    return {"ok": True}


@router.delete("/follow", status_code=status.HTTP_200_OK)
def unfollow(body: FollowRequest) -> dict:
    with get_conn() as conn:
        conn.execute(
            "DELETE FROM follows WHERE follower_id = ? AND following_id = ?",
            (body.followerId, body.followingId),
        )
    return {"ok": True}


@router.get("/users/{username}/followers", response_model=list[User])
def get_followers(username: str) -> list[User]:
    with get_conn() as conn:
        target = _require_user_by_username(conn, username)
        rows = conn.execute(
            """
            SELECT u.* FROM users u
            JOIN follows f ON f.follower_id = u.id
            WHERE f.following_id = ?
            ORDER BY f.created_at DESC
            """,
            (target["id"],),
        ).fetchall()
        return [_row_to_user(r, conn) for r in rows]


@router.get("/users/{username}/following", response_model=list[User])
def get_following(username: str) -> list[User]:
    with get_conn() as conn:
        target = _require_user_by_username(conn, username)
        rows = conn.execute(
            """
            SELECT u.* FROM users u
            JOIN follows f ON f.following_id = u.id
            WHERE f.follower_id = ?
            ORDER BY f.created_at DESC
            """,
            (target["id"],),
        ).fetchall()
        return [_row_to_user(r, conn) for r in rows]


@router.get("/users/{username}/shared-coupons", response_model=list[SharedCoupon])
def get_shared_coupons(username: str) -> list[SharedCoupon]:
    with get_conn() as conn:
        target = _require_user_by_username(conn, username)
        rows = conn.execute(
            """
            SELECT * FROM shared_coupons
            WHERE owner_id = ? AND is_public = 1
            ORDER BY created_at DESC
            """,
            (target["id"],),
        ).fetchall()
        return [
            SharedCoupon(
                id=r["id"],
                couponId=r["coupon_id"],
                ownerId=r["owner_id"],
                isPublic=bool(r["is_public"]),
                createdAt=r["created_at"],
            )
            for r in rows
        ]


# ── Share coupon endpoint ──────────────────────────────────────────────────────


class SharedCouponCreate(BaseModel):
    couponId:      str = Field(..., min_length=1)
    ownerUsername: str = Field(..., min_length=1)
    isPublic:      bool = True


@router.post("/shared-coupons", response_model=SharedCoupon, status_code=status.HTTP_200_OK)
def create_or_update_shared_coupon(body: SharedCouponCreate) -> SharedCoupon:
    """
    Create or update a shared coupon record.
    If (coupon_id, owner_id) already exists, updates is_public.
    Returns the created or updated record.
    """
    with get_conn() as conn:
        owner = _require_user_by_username(conn, body.ownerUsername)
        owner_id = owner["id"]

        existing = conn.execute(
            "SELECT * FROM shared_coupons WHERE coupon_id = ? AND owner_id = ?",
            (body.couponId, owner_id),
        ).fetchone()

        if existing:
            conn.execute(
                "UPDATE shared_coupons SET is_public = ? WHERE id = ?",
                (1 if body.isPublic else 0, existing["id"]),
            )
            row = conn.execute(
                "SELECT * FROM shared_coupons WHERE id = ?", (existing["id"],)
            ).fetchone()
        else:
            conn.execute(
                "INSERT INTO shared_coupons (coupon_id, owner_id, is_public) VALUES (?, ?, ?)",
                (body.couponId, owner_id, 1 if body.isPublic else 0),
            )
            row = conn.execute(
                "SELECT * FROM shared_coupons WHERE coupon_id = ? AND owner_id = ? ORDER BY created_at DESC LIMIT 1",
                (body.couponId, owner_id),
            ).fetchone()

        return SharedCoupon(
            id=row["id"],
            couponId=row["coupon_id"],
            ownerId=row["owner_id"],
            isPublic=bool(row["is_public"]),
            createdAt=row["created_at"],
        )


# ── Coupon detail endpoints ───────────────────────────────────────────────────


class _SelectionCreate(BaseModel):
    matchName: str = ""
    betType:   str = ""
    status:    str = "pending"
    lastScore: str = ""


class CouponDetailCreate(BaseModel):
    couponId:      str = Field(..., min_length=1)
    ownerUsername: str = Field(..., min_length=1)
    title:         str = ""
    siteName:      str = ""
    stake:         str = ""
    odds:          str = ""
    potential:     str = ""
    status:        str = "pending"
    selections:    list[_SelectionCreate] = Field(default_factory=list)


class _SelectionOut(BaseModel):
    matchName: str
    betType:   str
    status:    str
    lastScore: str


class CouponDetailOut(BaseModel):
    couponId:         str
    ownerUsername:    str
    ownerDisplayName: str
    title:            str
    siteName:         str
    stake:            str
    odds:             str
    potential:        str
    status:           str
    createdAt:        str
    selections:       list[_SelectionOut]


def _fetch_coupon_detail_row(conn: sqlite3.Connection, coupon_id: str) -> CouponDetailOut:
    row = conn.execute(
        """
        SELECT cd.*, u.username, u.display_name
        FROM coupon_details cd
        LEFT JOIN users u ON cd.owner_id = u.id
        WHERE cd.coupon_id = ?
        """,
        (coupon_id,),
    ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Coupon not found")
    sels = conn.execute(
        "SELECT * FROM coupon_selections WHERE coupon_id = ? ORDER BY sort_order",
        (coupon_id,),
    ).fetchall()
    return CouponDetailOut(
        couponId=row["coupon_id"],
        ownerUsername=row["username"] or "",
        ownerDisplayName=row["display_name"] or "",
        title=row["title"],
        siteName=row["site_name"],
        stake=row["stake"],
        odds=row["odds"],
        potential=row["potential"],
        status=row["status"],
        createdAt=row["created_at"],
        selections=[
            _SelectionOut(
                matchName=s["match_name"],
                betType=s["bet_type"],
                status=s["status"],
                lastScore=s["last_score"],
            )
            for s in sels
        ],
    )


@router.post("/coupons", response_model=CouponDetailOut, status_code=status.HTTP_200_OK)
def save_coupon_detail(body: CouponDetailCreate) -> CouponDetailOut:
    """Upsert full coupon detail. Called when user shares a coupon."""
    with get_conn() as conn:
        owner = _require_user_by_username(conn, body.ownerUsername)
        owner_id = owner["id"]

        existing = conn.execute(
            "SELECT 1 FROM coupon_details WHERE coupon_id = ?", (body.couponId,)
        ).fetchone()

        if existing:
            conn.execute(
                """
                UPDATE coupon_details
                SET title=?, site_name=?, stake=?, odds=?, potential=?, status=?
                WHERE coupon_id=?
                """,
                (body.title, body.siteName, body.stake, body.odds,
                 body.potential, body.status, body.couponId),
            )
        else:
            conn.execute(
                """
                INSERT INTO coupon_details
                    (coupon_id, owner_id, title, site_name, stake, odds, potential, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (body.couponId, owner_id, body.title, body.siteName,
                 body.stake, body.odds, body.potential, body.status),
            )

        # Replace selections
        conn.execute(
            "DELETE FROM coupon_selections WHERE coupon_id = ?", (body.couponId,)
        )
        for i, sel in enumerate(body.selections):
            conn.execute(
                """
                INSERT INTO coupon_selections
                    (coupon_id, match_name, bet_type, status, last_score, sort_order)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (body.couponId, sel.matchName, sel.betType,
                 sel.status, sel.lastScore, i),
            )

        return _fetch_coupon_detail_row(conn, body.couponId)


def _row_get(row: sqlite3.Row, *names: str, default: str = "") -> str:
    """Case-insensitive column accessor. Returns first non-empty match."""
    row_keys = {k.lower(): k for k in row.keys()}
    for n in names:
        actual = row_keys.get(n.lower())
        if actual is not None:
            v = row[actual]
            s = str(v) if v is not None else ""
            if s not in ("", "None", "-"):
                return s
    return default


def _fetch_from_kuponbot_db(
    coupon_id: str,
    owner_username: str,
    owner_display: str,
) -> Optional[CouponDetailOut]:
    """
    Read coupon + selections directly from kupon_bot.db.
    Uses PRAGMA table_info for column-name discovery so it survives schema
    changes.  Returns None on any error so the caller can fall through.
    """
    _STATUS_MAP = {
        "active":    "pending",
        "won":       "winning",
        "lost":      "risk",
        "cancelled": "cancelled",
        "pending":   "pending",
        "winning":   "winning",
        "risk":      "risk",
    }

    def _map_status(raw: str) -> str:
        return _STATUS_MAP.get(raw.strip().lower(), raw.lower())

    try:
        conn = sqlite3.connect(KUPONBOT_DB_PATH)
        conn.row_factory = sqlite3.Row
        try:
            row = conn.execute(
                "SELECT * FROM coupons WHERE id = ?", (coupon_id,)
            ).fetchone()
            if row is None:
                return None

            # Read PRAGMA so we can fall back to positional column names
            _pragma = conn.execute("PRAGMA table_info(coupons)").fetchall()
            _col_by_pos = [r[1] for r in _pragma]  # index → real column name
            print(f"[kuponbot] coupons cols: {_col_by_pos}", file=sys.stderr)

            def _pos(n: int) -> str:
                """Return column name at position n (if it exists)."""
                return _col_by_pos[n] if len(_col_by_pos) > n else ""

            # odds: try common names + positional fallback (position 1 in known schema)
            odds_raw = _row_get(
                row, "odds", "odd", "ratio", "multiplier", "oran",
                "toplam_oran", "total_odds", "katsayi", "carpan",
                _pos(1),
            )
            status_raw    = _row_get(row, "status", "durum", "state")
            created_raw   = _row_get(row, "created_at", "date", "timestamp")
            # stake: try common names + positional fallback (position 4)
            stake_raw = _row_get(
                row, "stake", "amount", "bahis", "bet_amount",
                "miktar", "tutar", "yatirim",
                _pos(4),
            )
            potential_raw = _row_get(row, "potential", "kazanc", "win_amount", "payout")
            site_raw      = _row_get(row, "site_name", "site", "platform", "bookmaker")
            title_raw     = _row_get(row, "title", "name", "description", "note",
                                     default=f"Kupon #{coupon_id}")

            # Compute potential from stake × odds when not stored
            if not potential_raw:
                try:
                    potential_raw = f"{float(stake_raw) * float(odds_raw):.0f}"
                except Exception:
                    potential_raw = ""

            # Format helpers
            def _fmt_money(v: str) -> str:
                try:
                    return f"₺{float(v):.0f}"
                except Exception:
                    return v

            def _fmt_odds(v: str) -> str:
                try:
                    return f"×{float(v):.2f}".rstrip('0').rstrip('.')
                except Exception:
                    return v

            def _fmt_potential(v: str) -> str:
                try:
                    return f"₺{float(v):.0f} beklenti"
                except Exception:
                    return v

            sel_rows = conn.execute(
                "SELECT * FROM selections WHERE coupon_id = ? ORDER BY id",
                (coupon_id,),
            ).fetchall()

            selections: list[_SelectionOut] = []
            for sr in sel_rows:
                match_name = _row_get(sr, "match_name", "home_away", "teams",
                                      "home_team", "match")
                bet_type   = _row_get(sr, "bet_type", "selection", "tip",
                                      "pick", "prediction")
                sel_status = _row_get(sr, "status", "result", "durum")
                score      = _row_get(sr, "last_score", "score", "skor",
                                      "result_score")
                selections.append(_SelectionOut(
                    matchName=match_name,
                    betType=bet_type,
                    status=_map_status(sel_status),
                    lastScore=score,
                ))

            return CouponDetailOut(
                couponId=str(coupon_id),
                ownerUsername=owner_username,
                ownerDisplayName=owner_display,
                title=title_raw,
                siteName=site_raw,
                stake=_fmt_money(stake_raw),
                odds=_fmt_odds(odds_raw),
                potential=_fmt_potential(potential_raw),
                status=_map_status(status_raw),
                createdAt=created_raw,
                selections=selections,
            )
        finally:
            conn.close()

    except Exception as exc:
        print(f"[social_router] kuponbot_db error: {exc}", file=sys.stderr)
        return None


@router.get("/coupons/{coupon_id}", response_model=CouponDetailOut)
def get_coupon_detail(coupon_id: str) -> CouponDetailOut:
    # 1. Try social.db (data saved at share time)
    with get_conn() as conn:
        existing = conn.execute(
            "SELECT 1 FROM coupon_details WHERE coupon_id = ?", (coupon_id,)
        ).fetchone()
        if existing:
            return _fetch_coupon_detail_row(conn, coupon_id)

    # 2. Fall back to kupon_bot.db (real bot data)
    owner_username = ""
    owner_display  = ""
    try:
        with get_conn() as conn:
            sc = conn.execute(
                """
                SELECT u.username, u.display_name
                FROM   shared_coupons sc
                JOIN   users u ON u.id = sc.owner_id
                WHERE  sc.coupon_id = ?
                LIMIT  1
                """,
                (coupon_id,),
            ).fetchone()
            if sc:
                owner_username = sc["username"]
                owner_display  = sc["display_name"]
    except Exception:
        pass

    detail = _fetch_from_kuponbot_db(coupon_id, owner_username, owner_display)
    if detail:
        return detail

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"Coupon '{coupon_id}' not found",
    )


# ── User search ───────────────────────────────────────────────────────────────

@router.get("/find-users", response_model=list[User])
def find_users(q: str = "") -> list[User]:
    """Search users by username or displayName (case-insensitive, partial).
    Uses /find-users path to avoid collision with /users/{username}."""
    if not q.strip():
        return []
    pattern = f"%{q.strip()}%"
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT * FROM users
            WHERE  LOWER(username)     LIKE LOWER(?)
               OR  LOWER(display_name) LIKE LOWER(?)
            ORDER  BY username
            LIMIT  20
            """,
            (pattern, pattern),
        ).fetchall()
        return [_row_to_user(r, conn) for r in rows]


# ── Activity feed ─────────────────────────────────────────────────────────────

class FeedItem(BaseModel):
    type:        str   # SHARED_COUPON | COUPON_WON | COUPON_LOST
    username:    str
    displayName: str
    couponId:    str
    createdAt:   str


@router.get("/feed/{username}", response_model=list[FeedItem])
def get_feed(username: str) -> list[FeedItem]:
    """Return recent coupon activity from users that {username} follows."""
    with get_conn() as conn:
        target = _require_user_by_username(conn, username)
        following = conn.execute(
            "SELECT following_id FROM follows WHERE follower_id = ?",
            (target["id"],),
        ).fetchall()
        if not following:
            return []

        following_ids = [r["following_id"] for r in following]
        placeholders  = ",".join("?" * len(following_ids))
        rows = conn.execute(
            f"""
            SELECT sc.coupon_id, sc.created_at,
                   u.username,   u.display_name,
                   cd.status     AS coupon_status
            FROM   shared_coupons sc
            JOIN   users u  ON u.id = sc.owner_id
            LEFT JOIN coupon_details cd ON cd.coupon_id = sc.coupon_id
            WHERE  sc.owner_id IN ({placeholders})
              AND  sc.is_public = 1
            ORDER  BY sc.created_at DESC
            LIMIT  50
            """,
            following_ids,
        ).fetchall()

        _STATUS_WON  = {"winning", "won"}
        _STATUS_LOST = {"risk", "cancelled", "lost"}
        items = []
        for r in rows:
            s = (r["coupon_status"] or "pending").lower()
            if s in _STATUS_WON:
                etype = "COUPON_WON"
            elif s in _STATUS_LOST:
                etype = "COUPON_LOST"
            else:
                etype = "SHARED_COUPON"
            items.append(FeedItem(
                type=etype,
                username=r["username"],
                displayName=r["display_name"],
                couponId=r["coupon_id"],
                createdAt=r["created_at"],
            ))
        return items
