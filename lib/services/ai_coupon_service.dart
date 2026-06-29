import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiCouponService {
  AiCouponService._();
  static final instance = AiCouponService._();

  Future<Map<String, dynamic>?> analyzeCouponImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final response = await http.post(
      Uri.parse('http://167.172.182.128:8001/ai/analyze-coupon'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_base64': base64Image,
        'media_type': mediaType,
        'user_id': userId,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data['success'] == true) return data['data'] as Map<String, dynamic>;
    return null;
  }
}