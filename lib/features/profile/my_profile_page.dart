import 'package:flutter/material.dart';

import '../../models/coupon.dart';
import '../../services/auth_service.dart';
import 'profile_page.dart';

class MyProfilePage extends StatelessWidget {
  final AppUser? user;
  final List<Coupon> coupons;

  const MyProfilePage({
    super.key,
    required this.user,
    required this.coupons,
  });

  @override
  Widget build(BuildContext context) {
    final username = user?.username ?? 'user';
    return ProfilePage(
      username: username,
      localCoupons: coupons,
      currentUsername: username,
    );
  }
}
