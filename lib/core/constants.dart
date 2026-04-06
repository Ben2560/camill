import 'package:flutter/material.dart';

class AppConstants {
  // FastAPI base URL (localhost for development)
  static const String apiBaseUrl = 'http://172.20.10.10:8000/v1';

  // Category labels (Japanese)
  static const Map<String, String> categoryLabels = {
    'food':         '食費',
    'dining_out':   '食費',
    'daily':        '日用品',
    'transport':    '交通費',
    'clothing':     '衣服',
    'social':       '交際費',
    'hobby':        '趣味',
    'medical':      '医療',
    'education':    '教育・書籍',
    'utility':      '光熱費',
    'subscription': 'サブスク',
    'other':        'その他',
  };

  // Category colors (badge background: withAlpha(30), text/border: full color)
  static const Map<String, Color> categoryColors = {
    'food':         Color(0xFFFF8A65), // 食費        - オレンジ
    'dining_out':   Color(0xFFFF7043), // 外食費      - ディープオレンジ
    'daily':        Color(0xFF4DB6AC), // 日用品      - ティール
    'transport':    Color(0xFF4FC3F7), // 交通費      - ライトブルー
    'clothing':     Color(0xFFF06292), // 衣服        - ピンク
    'social':       Color(0xFFFFB74D), // 交際費      - アンバー
    'hobby':        Color(0xFF9575CD), // 趣味        - パープル
    'medical':      Color(0xFFE57373), // 医療        - レッド
    'education':    Color(0xFF4CAF50), // 教育・書籍  - グリーン
    'utility':      Color(0xFF0097A7), // 光熱費      - シアン
    'subscription': Color(0xFF7986CB), // サブスク    - インディゴ
    'other':        Color(0xFF90A4AE), // その他      - グレー
  };

  // Legal page URLs (update when pages are published)
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  // Payment method labels
  static const Map<String, String> paymentLabels = {
    'cash': '現金',
    'credit': 'クレカ',
    'ic': 'IC/電子マネー',
    'qr': 'QRコード',
    'pay_easy': 'ペイジー',
    'other': 'その他',
  };
}
