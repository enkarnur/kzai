// lib/services/storage.dart
//
// 使用 SharedPreferences 存储：API Key、对话历史。

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class AppStorage {
  static const _kApiKey = 'deepseek_api_key';
  static const _kHistory = 'chat_history_v1';

  final SharedPreferences _prefs;
  AppStorage(this._prefs);

  static Future<AppStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  // -------- API Key --------
  String? getApiKey() {
    final v = _prefs.getString(_kApiKey);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<void> setApiKey(String key) async {
    await _prefs.setString(_kApiKey, key.trim());
  }

  Future<void> clearApiKey() async {
    await _prefs.remove(_kApiKey);
  }

  // -------- History --------
  List<ChatMessage> loadHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ChatMessage.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<ChatMessage> messages) async {
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(_kHistory, raw);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_kHistory);
  }
}
