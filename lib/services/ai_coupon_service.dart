import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiCouponService {
  AiCouponService._();
  static final instance = AiCouponService._();

  static const _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const _model = 'claude-sonnet-4-6';

  Future<Map<String, dynamic>?> analyzeCouponImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text': '''Bu bir bahis kuponu ekran görüntüsü. Kuponu analiz et ve aşağıdaki JSON formatında döndür. Sadece JSON döndür, başka hiçbir şey yazma:

{
  "site": "bahis sitesi adı",
  "stake": "bahis miktarı (sadece sayı, örn: 100)",
  "total_odds": "toplam oran (örn: 3.45)",
  "matches": [
    {
      "teams": "Ev Sahibi – Deplasman",
      "selection": "bahis seçimi (örn: MS1, Üst 2.5, KG Var, IY 1-0)",
      "odds": "bu maçın oranı"
    }
  ]
}

Eğer bir bilgi görünmüyorsa null yaz. Takım adlarını Türkçe olarak yaz.'''
              }
            ],
          }
        ],
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final text = (data['content'] as List).first['text'] as String;

    try {
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
