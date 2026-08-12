// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../services/storage.dart';

class SettingsScreen extends StatefulWidget {
  final AppStorage storage;
  /// 首次启动进入时为 true，不允许直接返回（必须先填 Key）
  final bool firstRun;

  const SettingsScreen({
    super.key,
    required this.storage,
    this.firstRun = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.storage.getApiKey() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final k = _controller.text.trim();
    if (k.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key бос болмауы керек')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.storage.setApiKey(k);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 首次启动必须先填 key
        if (widget.firstRun && (widget.storage.getApiKey() == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Алдымен API Key енгізіңіз')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Баптаулар'),
          automaticallyImplyLeading: !widget.firstRun,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DeepSeek API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                autofocus: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'sk-...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Кілт құрылғыда ғана сақталады, ешбір серверге жіберілмейді.\n'
                '(密钥仅保存在本机，不上传任何服务器)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сақтау'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
