enum CouponStatus {
  winning,
  risk,
  pending,
  cancelled,
  void_,
}

class Coupon {
  /// Real backend coupon ID (matches KuponBot's coupons.id integer).
  /// Used as the stable identifier for social sharing.
  final String? id;
  final String title;
  final String meta;
  final CouponStatus status;
  final String stake;
  final String potential;
  final List<CouponStatus> progress;
  final List<MatchItem> matches;

  // TODO(live-shared-coupon): Persist sharedId server-side to enable live
  //   tracking — followers open the link and see real-time selection updates.
  // TODO(friends-following): Notify followers when a friend shares a coupon
  //   (requires push notification + follow graph).
  final String? sharedId;
  final DateTime? createdAt;

  const Coupon({
    this.id,
    required this.title,
    required this.meta,
    required this.status,
    required this.stake,
    required this.potential,
    required this.progress,
    required this.matches,
    this.sharedId,
    this.createdAt,
  });

  /// Returns a new [Coupon] with any supplied fields replaced.
  Coupon copyWith({CouponStatus? status, String? sharedId}) => Coupon(
        id: id,
        title: title,
        meta: meta,
        status: status ?? this.status,
        stake: stake,
        potential: potential,
        progress: progress,
        matches: matches,
        sharedId: sharedId ?? this.sharedId,
      );
}

class MatchItem {
  final String teams;
  final String selection;
  final String score;
  final String minute;
  final CouponStatus status;

  const MatchItem({
    required this.teams,
    required this.selection,
    required this.score,
    required this.minute,
    required this.status,
  });
}

extension CouponX on Coupon {
  Coupon copyWithMatches(List<MatchItem> matches) => Coupon(
    id: id,
    title: title,
    meta: meta,
    status: status,
    stake: stake,
    potential: potential,
    progress: progress,
    matches: matches,
    sharedId: sharedId,
  );
}
