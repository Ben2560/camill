import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import 'api_service.dart';
import 'user_prefs.dart';

const _keyIsOverseas = 'is_overseas';
const _keyCurrency = 'current_currency';
const _keyLastCountry = 'last_country_code';

/// 対応通貨コードの国コード→通貨コードマッピング
const Map<String, String> _countryCurrencyMap = {
  'US': 'USD', 'GB': 'GBP', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR',
  'ES': 'EUR', 'NL': 'EUR', 'PT': 'EUR', 'AT': 'EUR', 'BE': 'EUR',
  'FI': 'EUR', 'IE': 'EUR', 'GR': 'EUR', 'CN': 'CNY', 'TH': 'THB',
  'KR': 'KRW', 'TW': 'TWD', 'SG': 'SGD', 'AU': 'AUD', 'HK': 'HKD',
  'PH': 'PHP', 'VN': 'VND', 'ID': 'IDR', 'MY': 'MYR', 'IN': 'INR',
};

/// 国コードの日本語名（通知文言用）
const Map<String, String> _countryNames = {
  'US': 'アメリカ', 'GB': 'イギリス', 'DE': 'ドイツ', 'FR': 'フランス',
  'IT': 'イタリア', 'ES': 'スペイン', 'CN': '中国', 'TH': 'タイ',
  'KR': '韓国', 'TW': '台湾', 'SG': 'シンガポール', 'AU': 'オーストラリア',
  'HK': '香港', 'PH': 'フィリピン', 'VN': 'ベトナム', 'ID': 'インドネシア',
  'MY': 'マレーシア', 'IN': 'インド',
};

class OverseasDetectionResult {
  final bool isOverseas;
  final String countryCode;
  final String currency;
  final String? countryName;

  OverseasDetectionResult({
    required this.isOverseas,
    required this.countryCode,
    required this.currency,
    this.countryName,
  });
}

class OverseasService {
  final ApiService _api;

  OverseasService(this._api);

  Future<bool> getIsOverseas() async {
    final p = await SharedPreferences.getInstance();
    return (await UserPrefs.getBool(p, _keyIsOverseas)) ?? false;
  }

  Future<String> getCurrentCurrency() async {
    final p = await SharedPreferences.getInstance();
    return (await UserPrefs.getString(p, _keyCurrency)) ?? 'JPY';
  }

  Future<void> _saveLocally(bool isOverseas, String currency, String countryCode) async {
    final p = await SharedPreferences.getInstance();
    await UserPrefs.setBool(p, _keyIsOverseas, isOverseas);
    await UserPrefs.setString(p, _keyCurrency, currency);
    await UserPrefs.setString(p, _keyLastCountry, countryCode);
  }

  /// 位置情報から国コードを取得する（Nominatim逆ジオコーディング）
  Future<String?> _getCountryCode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
      );
      final res = await http.get(url, headers: {'User-Agent': 'camill-app/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        return address?['country_code']?.toString().toUpperCase();
      }
    } catch (_) {}
    return null;
  }

  /// 現在地の国を取得し、前回と異なれば OverseasDetectionResult を返す。
  /// 変化なし・取得失敗の場合は null を返す。
  Future<OverseasDetectionResult?> detectCountryChange() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }

    final countryCode = await _getCountryCode(position.latitude, position.longitude);
    if (countryCode == null) return null;

    final p = await SharedPreferences.getInstance();
    final lastCountry = await UserPrefs.getString(p, _keyLastCountry);

    if (countryCode == lastCountry) return null;

    final isOverseas = countryCode != 'JP';
    final currency = isOverseas
        ? (_countryCurrencyMap[countryCode] ?? 'JPY')
        : 'JPY';
    final countryName = isOverseas ? _countryNames[countryCode] : null;

    return OverseasDetectionResult(
      isOverseas: isOverseas,
      countryCode: countryCode,
      currency: currency,
      countryName: countryName ?? countryCode,
    );
  }

  /// is_overseas と current_currency をバックエンドと SharedPreferences に保存する。
  Future<void> applyOverseasStatus({
    required bool isOverseas,
    required String currency,
    required String countryCode,
  }) async {
    await _saveLocally(isOverseas, currency, countryCode);
    try {
      await _api.patch('/exchange-rates/overseas', body: {
        'is_overseas': isOverseas,
        'current_currency': currency,
      });
    } catch (_) {
      // オフラインでも継続（ローカルには保存済み）
    }
  }

  /// 為替レート一覧を取得する（認証不要）
  Future<Map<String, dynamic>> fetchRates() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/exchange-rates');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// 指定通貨の直近3日履歴を取得する（認証不要）
  Future<List<Map<String, dynamic>>> fetchRateHistory(String currency) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/exchange-rates/history?currency=$currency');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }
    } catch (_) {}
    return [];
  }
}
