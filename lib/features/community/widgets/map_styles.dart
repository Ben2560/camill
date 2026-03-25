/// isDark に応じてマップスタイルを返す
String communityMapStyle(bool isDark) {
  return isDark ? _midnightStyle : _classicStyle;
}

/// Midnight ダークモード地図
const _midnightStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1117"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8b949e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1117"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#21262d"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#484f58"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0d1117"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#161b22"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#8b949e"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#132418"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#21262d"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#161b22"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#30363d"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#21262d"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#161b22"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0e14"}]}
]
''';

/// Classic White ライトモード地図
const _classicStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4a4a5e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#e0e4ee"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f8faff"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#f0f2fa"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#e0f0e0"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f0f2fa"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e0e4ee"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e8ecf6"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#d0d4e0"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#f0f2fa"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d4e4f4"}]}
]
''';
