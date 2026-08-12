// lib/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final fg = isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    // 因为整个应用是 RTL，user 消息应贴 "起始"（视觉上右侧），
    // assistant 消息贴 "末端"（视觉上左侧）。在 RTL 里 start=right，end=left。
    final alignment =
        isUser ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: SelectableText(
            message.arabic.isNotEmpty ? message.arabic : message.cyrillic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: fg,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
