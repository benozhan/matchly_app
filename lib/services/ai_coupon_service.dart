import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiMatchResult {
  final String original;
  final String? matched;
  final String selection;
  final String odds;

  AiMatchResult({required this.original, this.matched, required this.selection, required this.odds});
  bool get isMatched => matched != null;
}

class AiCouponResult {
  final String? site;
  final String? stake;
  final String? totalOdds;
  final List<AiMatchResult> matches;

  AiCouponResult({this.site, this.stake, this.totalOdds, required this.matches});
  List<AiMatchResult> get matchedMatches => matches.where((m) => m.isMatched).toList();
  List<AiMatchResult> get unmatchedMatches => matches.where((m) => !m.isMatched).toList();
}

class AiCouponService {
  AiCouponService._();
  static final instance = AiCouponService._();

  Future<AiCouponResult?> analyzeCouponImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final analyzeRes = await http.post(
      Uri.parse('http://167.172.182.128:8001/ai/analyze-coupon'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_base64': base64Image, 'media_type': mediaType, 'user_id': userId}),
    ).timeout(const Duration(seconds: 30));

    if (analyzeRes.statusCode != 200) return null;
    final analyzeData = jsonDecode(analyzeRes.body);
    if (analyzeData['success'] != true) return null;
    final couponData = analyzeData['data'] as Map<String, dynamic>;
    final rawMatches = (couponData['matches'] as List? ?? []);

    final verifyRes = await http.post(
      Uri.parse('http://167.172.182.128:8001/ai/verify-matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'matches': rawMatches}),
    ).timeout(const Duration(seconds: 15));

    List<AiMatchResult> matchResults = [];
    if (verifyRes.statusCode == 200) {
      final verifyData = jsonDecode(verifyRes.body);
      if (verifyData['success'] == true) {
        for (final r in verifyData['results'] as List) {
          matchResults.add(AiMatchResult(
            original: r['original'] ?? '',
            matched: r['matched'],
            selection: r['selection'] ?? '',
            odds: r['odds']?.toString() ?? '',
          ));
        }
      }
    }

    return AiCouponResult(
      site: couponData['site']?.toString(),
      stake: couponData['stake']?.toString(),
      totalOdds: couponData['total_odds']?.toString(),
      matches: matchResults,
    );
  }
}
