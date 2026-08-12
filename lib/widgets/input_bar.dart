// lib/widgets/input_bar.dart

import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final bool sending;
  final bool listening;
  final void Function(String text) onSend;
  final VoidCallback onMicPressed;

  const InputBar({
    super.key,
    required this.sending,
    required this.listening,
    required this.onSend,
    required this.onMicPressed,
  });

  @override
  State<InputBar> createState() => InputBarState();
}

class InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();

  /// 供父级把语音识别结果写入输入框
  void setText(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void appendText(String text) => setText(_controller.text + text);

  void clear() => _controller.clear();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isEmpty || widget.sending) return;
    widget.onSend(t);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Дауыс', // 语音
              icon: Icon(
                widget.listening ? Icons.mic : Icons.mic_none,
                color: widget.listening ? Colors.red : theme.iconTheme.color,
              ),
              onPressed: widget.sending ? null : widget.onMicPressed,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                enabled: !widget.sending,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'سۇراق جازىڭىز...', // "写下你的问题..."
                  hintTextDirection: TextDirection.rtl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            widget.sending
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Жіберу', // 发送
                    icon: const Icon(Icons.send),
                    onPressed: _submit,
                  ),
          ],
        ),
      ),
    );
  }
}
