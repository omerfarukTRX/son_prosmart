import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GPTService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey;

  GPTService(this._apiKey);

  // Retry mekanizmalı metod
  Future<String> getResponseWithRetry(String question,
      {int maxAttempts = 3}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        return await getResponse(question);
      } catch (e) {
        print('Deneme ${i + 1} başarısız: $e');
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    throw Exception('Maksimum deneme sayısına ulaşıldı');
  }

  String formatResponse(String content) {
    // Bölüm başlıklarını kontrol et ve düzelt
    if (!content.contains('YASAL DAYANAK:')) {
      content = 'YASAL DAYANAK:\n$content';
    }
    if (!content.contains('AÇIKLAMA:')) {
      content = '$content\n\nAÇIKLAMA:\n';
    }
    if (!content.contains('PRATİK ÇÖZÜM:')) {
      content = '$content\n\nPRATİK ÇÖZÜM:\n';
    }

    // Yanıtı formatla
    return content
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Fazla boş satırları temizle
        .replaceAll('YASAL DAYANAK:', '\n\nYASAL DAYANAK:')
        .replaceAll('AÇIKLAMA:', '\n\nAÇIKLAMA:')
        .replaceAll('PRATİK ÇÖZÜM:', '\n\nPRATİK ÇÖZÜM:')
        .trim();
  }

  // Ana API çağrı metodu
  Future<String> getResponse(String question) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      };

      final systemContent =
          '''Sen bir kat mülkiyeti hukuku uzmanısın ve adın ömer sorulara  şu şekilde yanıt vermelisin:
                   
1. Her yanıt aşağıdaki bölümleri içermeli:

YASAL DAYANAK:
- Mutlaka 634 sayılı Kat Mülkiyeti Kanunu'nun ilgili maddelerini belirt
- Madde numaralarını açıkça yaz

AÇIKLAMA:
- Konuyu sade ve anlaşılır bir dille açıkla
- Hukuki terimleri gerektiğinde parantez içinde aç

PRATİK ÇÖZÜM:
- Maddi ve pratik öneriler sun
- Somut adımları sırala

2. Eğer sorulan konu kat mülkiyeti ile ilgili değilse, bunu belirt ve kat mülkiyeti ile ilgili hangi konuları cevaplayabileceğini açıkla.

3. Her zaman güncel 634 sayılı Kat Mülkiyeti Kanunu'na göre yanıt ver.

ÖRNEK SORU-CEVAPLAR:

Soru: "Kat malikleri kurulu nasıl toplanır?"
YASAL DAYANAK:
- KMK Madde 29 ve 30 uyarınca toplantı düzenlenir
- Madde 29'a göre yılda en az bir kez toplanılması zorunludur

AÇIKLAMA:
Kat malikleri kurulu, apartmanın en yetkili karar organıdır. Yönetici veya kat maliklerinin üçte biri tarafından toplantıya çağrılabilir.

PRATİK ÇÖZÜM:
1. Toplantı tarihinden en az 15 gün önce tüm kat maliklerine yazılı bildirim yapın
2. Gündemi açıkça belirtin
3. Toplantı tutanağı tutun

Soru: "Aidat ödemeyen komşu için ne yapabilirim?"
YASAL DAYANAK:
- KMK Madde 20 uyarınca aidatların ödenmesi zorunludur
- İcra takibi başlatılabilir

AÇIKLAMA:
Kat maliki, ortak giderlere katılmak zorundadır. Ödenmemesi durumunda yasal yollara başvurulabilir.

PRATİK ÇÖZÜM:
1. Önce yazılı uyarı gönderin
2. Yönetici aracılığıyla görüşme talep edin
3. Gerekirse icra takibi başlatın''';

      final body = jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': systemContent},
          {
            'role': 'user',
            'content': question,
          }
        ],
        'temperature': 0.3,
        'max_tokens': 800,
        'presence_penalty': 0.1,
        'frequency_penalty': 0.1,
      });

      print('İstek gönderiliyor...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      print('Yanıt alındı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;

        // Önce Türkçe karakterleri düzelt, sonra formatla
        final correctedContent = content
            .replaceAll('i̇', 'i')
            .replaceAll('İ', 'İ')
            .replaceAll('ı', 'ı')
            .replaceAll('Ş', 'Ş')
            .replaceAll('ş', 'ş')
            .replaceAll('Ğ', 'Ğ')
            .replaceAll('ğ', 'ğ')
            .replaceAll('Ü', 'Ü')
            .replaceAll('ü', 'ü')
            .replaceAll('Ö', 'Ö')
            .replaceAll('ö', 'ö')
            .replaceAll('Ç', 'Ç')
            .replaceAll('ç', 'ç');

        return formatResponse(correctedContent);
      } else {
        print('API Hata Detayı: ${utf8.decode(response.bodyBytes)}');
        throw Exception(
            'API yanıt hatası: ${response.statusCode}\nDetay: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Bağlantı hatası: $e');
      throw Exception('Bağlantı hatası: $e');
    }
  }
}
