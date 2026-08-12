// lib/main.dart

import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.init();
  runApp(KazakhChatApp(storage: storage));
}

class KazakhChatApp extends StatelessWidget {
  final AppStorage storage;
  const KazakhChatApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qazaq Chat',
      debugShowCheckedModeBanner: false,
      // 全局 RTL：整个 UI 从右向左布局，适配阿拉伯哈萨克文
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00AFCA), // 哈萨克国旗蓝
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00AFCA),
          brightness: Brightness.dark,
        ),
      ),
      home: _Bootstrapper(storage: storage),
    );
  }
}

/// 首次启动时，如果没有 API Key 就先跳到设置页；否则直接进聊天页。
class _Bootstrapper extends StatefulWidget {
  final AppStorage storage;
  const _Bootstrapper({required this.storage});

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (widget.storage.getApiKey() == null) {
      // 首次启动：先弹设置页
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              SettingsScreen(storage: widget.storage, firstRun: true),
        ),
      );
    }
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChatScreen(storage: widget.storage);
  }
}
