"""
Patch script: append POST /social/shared-coupons to social_router.py on VPS.
Run: python3 /opt/KuponBot/patch_share_endpoint.py
"""
import os

TARGET = os.path.join(os.path.dirname(__file__), "social_router.py")

ADDITION = '''

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
'''

with open(TARGET, "r") as f:
    src = f.read()

MARKER = "class SharedCouponCreate"
if MARKER in src:
    print("Already patched — skipping.")
else:
    with open(TARGET, "a") as f:
        f.write(ADDITION)
    print(f"Patched {TARGET}")
