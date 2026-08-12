// lib/services/transliteration.dart
//
// 阿拉伯哈萨克文 (Töte Jazu / Qazaq Arabic) ↔ 西里尔哈萨克文 转写器
//
// 说明：
//   * 采用中国新疆及部分中亚地区通用的 Töte Jazu 33 字母对应表；
//   * DeepSeek 模型主要理解现代哈萨克 Cyrillic，因此输入侧转成 Cyrillic 送模型；
//   * 回译时再把 Cyrillic 转回阿拉伯字母展示。
//
// 对个别多值对应（如 و → о/ұ、ي → и/й）采用最常见的默认；
// 如果发现某些词转写不准，可在 _arabicToCyrillic / _cyrillicToArabic 里微调。

class KazakhTransliterator {
  /// 阿拉伯哈萨克文 → 西里尔
  /// 使用单字符与多字符组合两个维度：先处理多字符组合（例如 'يا' → 'я'），再落回单字符表。
  static String arabicToCyrillic(String input) {
    if (input.isEmpty) return input;
    var buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      // 尝试匹配 3 字符 / 2 字符组合
      var matched = false;
      for (final len in [3, 2]) {
        if (i + len <= input.length) {
          final chunk = input.substring(i, i + len);
          final v = _arabicMulti[chunk];
          if (v != null) {
            buffer.write(v);
            i += len;
            matched = true;
            break;
          }
        }
      }
      if (matched) continue;
      final ch = input[i];
      buffer.write(_arabicToCyrillic[ch] ?? ch);
      i++;
    }
    return buffer.toString();
  }

  /// 西里尔 → 阿拉伯哈萨克文
  static String cyrillicToArabic(String input) {
    if (input.isEmpty) return input;
    var buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final lower = ch.toLowerCase();
      final mapped = _cyrillicToArabic[lower];
      buffer.write(mapped ?? ch);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // 阿拉伯 → 西里尔（多字符组合）
  static const Map<String, String> _arabicMulti = {
    'يا': 'я',
    'يۋ': 'ю',
    'يو': 'ё',
    'شش': 'щ',
    'تس': 'ц',
  };

  // 阿拉伯 → 西里尔（单字符）
  static const Map<String, String> _arabicToCyrillic = {
    'ا': 'а',
    'ٵ': 'ә',
    'ب': 'б',
    'ۆ': 'в',
    'گ': 'г',
    'ع': 'ғ',
    'د': 'д',
    'ە': 'е',
    'ج': 'ж',
    'ز': 'з',
    'ٸ': 'і', // 注意：与 и 存在歧义，Töte Jazu 中 і/и 均可能写作 ٸ 或 ي；这里默认 ٸ→і
    'ي': 'й',
    'ك': 'к',
    'ک': 'к', // 波斯/阿拉伯变体
    'ق': 'қ',
    'ل': 'л',
    'م': 'м',
    'ن': 'н',
    'ڭ': 'ң',
    'و': 'о',
    'ٶ': 'ө',
    'پ': 'п',
    'ر': 'р',
    'س': 'с',
    'ت': 'т',
    'ۋ': 'у',
    'ۇ': 'ұ',
    'ٷ': 'ү',
    'ف': 'ф',
    'ح': 'х',
    'ھ': 'һ',
    'ه': 'һ', // 常见变体
    'چ': 'ч',
    'ش': 'ш',
    'ى': 'ы',
    // 常见阿拉伯标点
    '،': ',',
    '؟': '?',
    '؛': ';',
    'ـ': '', // tatweel 忽略
  };

  // ---------------------------------------------------------------------------
  // 西里尔 → 阿拉伯（单字符）；多字符如 я / ю / ё 直接映射到组合串
  static const Map<String, String> _cyrillicToArabic = {
    'а': 'ا',
    'ә': 'ٵ',
    'б': 'ب',
    'в': 'ۆ',
    'г': 'گ',
    'ғ': 'ع',
    'д': 'د',
    'е': 'ە',
    'ё': 'يو',
    'ж': 'ج',
    'з': 'ز',
    'и': 'ي', // 借词中的长 и，写作 ي
    'й': 'ي',
    'к': 'ك',
    'қ': 'ق',
    'л': 'ل',
    'м': 'م',
    'н': 'ن',
    'ң': 'ڭ',
    'о': 'و',
    'ө': 'ٶ',
    'п': 'پ',
    'р': 'ر',
    'с': 'س',
    'т': 'ت',
    'у': 'ۋ',
    'ұ': 'ۇ',
    'ү': 'ٷ',
    'ф': 'ف',
    'х': 'ح',
    'һ': 'ھ',
    'ц': 'تس',
    'ч': 'چ',
    'ш': 'ش',
    'щ': 'شش',
    'ъ': '',
    'ы': 'ى',
    'і': 'ٸ',
    'ь': '',
    'э': 'ە',
    'ю': 'يۋ',
    'я': 'يا',
    // 标点保留原样即可，但把英式改成阿拉伯式更自然
    ',': '،',
    '?': '؟',
    ';': '؛',
  };
}
