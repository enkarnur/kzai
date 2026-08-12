// lib/services/deepseek_api.dart
//
// DeepSeek Chat Completions 客户端。
// 官方 API 与 OpenAI 兼容，接口：POST https://api.deepseek.com/chat/completions

import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekApi {
  static const String baseUrl = 'https://api.deepseek.com';
  static const String model = 'deepseek-chat';

  /// 用哈萨克语（西里尔字母）简短、直接地回答。
  static const String systemPrompt =
      'Сен қазақ тілінде сөйлейтін көмекшісің. '
      'Пайдаланушының сұрағына тек қазақ тілінде, кириллица әліпбиімен, '
      'қысқа және нақты жауап бер. '
      'Артық түсіндірмелерден, ағылшын не орыс сөздерінен аулақ бол. '
      'Тізім қажет болғанда 1., 2., 3. деп нөмірле.';

  final String apiKey;
  DeepSeekApi(this.apiKey);

  /// 发送对话历史（Cyrillic）并返回助手的 Cyrillic 回复。
  Future<String> chat(List<Map<String, String>> history) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final body = {
      'model': model,
      'stream': false,
      'temperature': 0.7,
      'max_tokens': 512,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...history,
      ],
    };

    final resp = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $apiKey',
          },
          body: utf8.encode(jsonEncode(body)),
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw DeepSeekException(
        'HTTP ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}',
      );
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw DeepSeekException('No choices returned: ${resp.body}');
    }
    final message = (choices.first as Map)['message'] as Map?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw DeepSeekException('Empty content in response');
    }
    return content.trim();
  }
}

class DeepSeekException implements Exception {
  final String message;
  DeepSeekException(this.message);
  @override
  String toString() => 'DeepSeekException: $message';
}
