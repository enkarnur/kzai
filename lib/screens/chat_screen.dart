// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../models/message.dart';
import '../services/deepseek_api.dart';
import '../services/storage.dart';
import '../services/transliteration.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final AppStorage storage;
  const ChatScreen({super.key, required this.storage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<InputBarState> _inputKey = GlobalKey<InputBarState>();
  final ScrollController _scroll = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;

  bool _sending = false;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages = widget.storage.loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (err) {
        if (mounted) setState(() => _listening = false);
        _snack('Дауыс тану қатесі: ${err.errorMsg}');
      },
    );
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -------- 语音 --------
  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    // 检查/请求麦克风权限
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _snack('Микрофон рұқсаты қажет');
      return;
    }
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        _snack('Дауыс тану қолжетімсіз');
        return;
      }
    }

    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'kk-KZ',
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onResult: (result) {
        // 语音识别默认返回的是西里尔（kk-KZ 是西里尔正字）；转回阿拉伯写入输入框。
        final cyr = result.recognizedWords;
        if (cyr.isEmpty) return;
        final arb = KazakhTransliterator.cyrillicToArabic(cyr);
        _inputKey.currentState?.setText(arb);
      },
    );
  }

  // -------- 发送 --------
  Future<void> _sendMessage(String arabicInput) async {
    final apiKey = widget.storage.getApiKey();
    if (apiKey == null) {
      _snack('Алдымен API Key енгізіңіз');
      return;
    }
    final cyrillicInput =
        KazakhTransliterator.arabicToCyrillic(arabicInput.trim());

    final userMsg = ChatMessage(
      role: MessageRole.user,
      arabic: arabicInput.trim(),
      cyrillic: cyrillicInput,
    );

    setState(() {
      _messages.add(userMsg);
      _sending = true;
    });
    await widget.storage.saveHistory(_messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 组装历史（都是 Cyrillic）
    final history = _messages
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.cyrillic,
            })
        .toList();

    try {
      final api = DeepSeekApi(apiKey);
      final replyCyr = await api.chat(history);
      final replyArb = KazakhTransliterator.cyrillicToArabic(replyCyr);

      final asst = ChatMessage(
        role: MessageRole.assistant,
        arabic: replyArb,
        cyrillic: replyCyr,
      );
      setState(() {
        _messages.add(asst);
        _sending = false;
      });
      await widget.storage.saveHistory(_messages);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _sending = false);
      _snack('Қате: $e');
    }
  }

  // -------- 顶部按钮 --------
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(storage: widget.storage),
      ),
    );
    if (mounted) setState(() {}); // 可能更新了 Key
  }

  Future<void> _clearHistory() async {
    if (_messages.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тарихты өшіру?'),
        content: const Text('Барлық хабарламалар жойылады.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Болдырмау'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Өшіру'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _messages = []);
      await widget.storage.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قازاق شاتى', style: TextStyle(fontSize: 20)), // "Qazaq Chat"
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Тарихты тазалау',
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty ? null : _clearHistory,
          ),
          IconButton(
            tooltip: 'Баптаулар',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
                  ),
          ),
          const Divider(height: 1),
          InputBar(
            key: _inputKey,
            sending: _sending,
            listening: _listening,
            onSend: _sendMessage,
            onMicPressed: _toggleMic,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'قازاقشا سۇراق قويىڭىز',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 6),
            Text(
              '(用哈萨克语向 AI 提问)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
