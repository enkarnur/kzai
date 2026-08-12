# Qazaq Chat · 哈萨克语智能问答（Flutter Android 应用）

一个面向哈萨克用户的极简聊天 App：
- 界面语言：哈萨克语（**阿拉伯字母**，RTL 布局）
- 支持键盘输入 & 设备语音识别（`kk-KZ`）
- 本地进行 **阿拉伯哈萨克文 ↔ 西里尔哈萨克文** 转写
- 把 Cyrillic 版本发给 **DeepSeek `deepseek-chat`**，用哈萨克语简短作答
- 回答再本地转回阿拉伯字母显示
- API Key、聊天历史都保存在本机（SharedPreferences）

## 目录结构

```
kazakh_chat_app/
├── pubspec.yaml              # Flutter 依赖
├── analysis_options.yaml
├── android/
│   └── app/src/main/AndroidManifest.xml   # 已配置网络 + 麦克风权限 + queries
├── lib/
│   ├── main.dart                          # App 入口 + 首次启动跳设置
│   ├── models/message.dart                # 聊天消息模型
│   ├── services/
│   │   ├── transliteration.dart           # 阿拉伯 ↔ 西里尔 字符对应表
│   │   ├── deepseek_api.dart              # DeepSeek Chat Completions 调用
│   │   └── storage.dart                   # SharedPreferences 封装
│   ├── screens/
│   │   ├── chat_screen.dart               # 主聊天界面
│   │   └── settings_screen.dart           # API Key 设置页
│   └── widgets/
│       ├── message_bubble.dart            # 聊天气泡
│       └── input_bar.dart                 # 底部输入栏（含麦克风）
└── README.md
```

> ⚠️ 本包**只包含核心源码**（Dart + AndroidManifest），Flutter 的
> Android 脚手架（Gradle、MainActivity、图标、启动屏等）会在你第一次运行
> `flutter create --platforms=android .` 时自动生成，**不会覆盖本仓库里已存在的
> AndroidManifest.xml**。这样做能保证跟你本地的 Flutter 版本完全兼容。

## 环境要求

- Flutter SDK **3.10+**（推荐 3.19+ / Dart 3.x）
- Android Studio 或 命令行 Android SDK
- Android SDK Platform 34 + Build-Tools
- 一台 Android 手机（**8.0 (API 26) 及以上**推荐；`speech_to_text` 需要 API 21+）

安装 Flutter：<https://docs.flutter.dev/get-started/install>

配置好后 `flutter doctor -v` 应全部 ✅。

## 一次性初始化（重要！）

进入项目目录：

```bash
cd kazakh_chat_app
```

**第一步**：让 Flutter 补齐 Android 平台脚手架（保留我们已经写好的 AndroidManifest.xml）：

```bash
flutter create \
  --platforms=android \
  --org com.qazaqchat \
  --project-name kazakh_chat \
  .
```

这一步会生成：
- `android/build.gradle`、`android/settings.gradle`、`gradle-wrapper.*`
- `android/app/build.gradle`、`MainActivity.kt`
- `android/app/src/main/res/**`（默认图标、启动屏、theme）

因为我们已经写好了 `android/app/src/main/AndroidManifest.xml`，Flutter 会**跳过**它。
如果你看到 Flutter 提示 “AndroidManifest.xml already exists, skipping.” 说明一切正常。

**第二步**：拉依赖：

```bash
flutter pub get
```

## 本地调试运行

插上手机（打开开发者模式和 USB 调试）：

```bash
flutter devices          # 确认设备已识别
flutter run              # 会自动装到手机上并热重载
```

首次启动 App，会先弹出**设置页**要求你输入 DeepSeek API Key（`sk-...`）。
保存后进入聊天页，可以在右上角 ⚙️ 里随时修改。

## 打包 APK

### 方式 A：命令行（推荐）

```bash
# release APK
flutter build apk --release

# 或按 CPU 架构拆分（体积更小，一次生成 3 个 APK）
flutter build apk --split-per-abi --release
```

产物路径：

```
build/app/outputs/flutter-apk/app-release.apk
# 或拆分后：
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

首次构建的 release APK 会**用 Flutter 内置的 debug keystore 签名**，可以直接装到自己的手机上；
如果要发布到应用商店，需要生成正式签名密钥并在 `android/key.properties` + `android/app/build.gradle`
里配置，参考 [Flutter 官方文档 → 签名 APK](https://docs.flutter.dev/deployment/android#signing-the-app)。

### 方式 B：Android Studio

1. `File → Open` 选中本项目根目录，等待 Gradle 同步。
2. `Build → Flutter → Build APK`。
3. 完成后底部 Event Log 里会出现 `locate` 链接，点击即可打开 `build/app/outputs/flutter-apk/`。

### 安装到手机

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

或直接把 APK 传到手机，用文件管理器点击安装（需要允许安装未知来源）。

## DeepSeek API 说明

- Base URL：`https://api.deepseek.com`
- Endpoint：`POST /chat/completions`（OpenAI 兼容）
- Model：`deepseek-chat`
- 认证：`Authorization: Bearer <YOUR_API_KEY>`
- 系统提示已在 `lib/services/deepseek_api.dart` 里写死为“用哈萨克语（Cyrillic）简短直接回答”。
  如需调整可修改 `DeepSeekApi.systemPrompt`。
- 申请 Key：<https://platform.deepseek.com/>

## 语音识别说明

- 使用 `speech_to_text` 插件，调用手机自带的 Google/厂商语音识别，locale 传 `kk-KZ`。
- 手机需要**安装并启用** Google App / Gboard，且下载了**哈萨克语（kk-KZ）离线包**或联网。
- 识别到的是 **Cyrillic**，App 会自动本地转成阿拉伯字母填入输入框，你可以再编辑后发送。
- 部分厂商 ROM（尤其国内定制 ROM）可能默认没有 kk-KZ；此时可安装 [Google 语音搜索/助理] 或在设置里
  切换 “Google 语音识别引擎”。

## 转写说明与已知限制

`lib/services/transliteration.dart` 里的对应表来自 Töte Jazu 33 字母标准：

| Cyrillic | Arabic | 备注 |
| :---: | :---: | :--- |
| а/ә/о/ө | ا / ٵ / و / ٶ | |
| ұ/ү/у | ۇ / ٷ / ۋ | |
| і/и/й | ٸ / ي / ي | **和/ي存在多义**，回译时默认 `ي → й` |
| қ/ғ/ң/һ | ق / ع / ڭ / ھ | |

由于 Töte Jazu 里 `ي` 同时代表 `и` 和 `й`，某些借词（例如俄语词）回译回阿拉伯字母后再转回 Cyrillic
可能会出现 `й/и` 的偏差。如需更严格的转写，可在 `_arabicToCyrillic` / `_cyrillicToArabic` 里根据你的
语料继续扩充多字符规则。

## 常见问题

**Q：`flutter run` 提示找不到 kotlin/MainActivity？**
A：说明你没跑过 `flutter create --platforms=android .`。执行这条命令后 Flutter 会自动补齐。

**Q：语音按钮按下没反应？**
A：先检查是否授予麦克风权限（设置 → 应用 → Qazaq Chat → 权限）；再确认手机装了支持 `kk-KZ` 的语音引擎。

**Q：请求 DeepSeek 报 401？**
A：Key 错了或过期，进设置页重新填。

**Q：聊天历史存在哪？想手动清除？**
A：SharedPreferences（App 私有数据）；点顶栏的🗑️按钮可一键清空。

**Q：APK 体积能不能再小？**
A：加 `--split-per-abi` 分架构；或改用 App Bundle：`flutter build appbundle --release`。

---

Жасаушы: 恩卡尔·努尔 · Made with Flutter 💙
