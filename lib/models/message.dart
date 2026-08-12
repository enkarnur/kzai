// lib/models/message.dart
//
// 聊天消息模型：同时存阿拉伯与西里尔两个版本，便于本地展示 & 送模型。

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  /// 阿拉伯哈萨克文（展示给用户）
  final String arabic;
  /// 西里尔哈萨克文（送模型 / 从模型返回）
  final String cyrillic;
  final DateTime createdAt;

  ChatMessage({
    required this.role,
    required this.arabic,
    required this.cyrillic,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'arabic': arabic,
        'cyrillic': cyrillic,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: MessageRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => MessageRole.user,
        ),
        arabic: (json['arabic'] as String?) ?? '',
        cyrillic: (json['cyrillic'] as String?) ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}
