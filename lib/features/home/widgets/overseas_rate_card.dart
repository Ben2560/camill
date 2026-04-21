import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/widgets/camill_card.dart';

const _currencyFlags = {
  'USD': '🇺🇸',
  'EUR': '🇪🇺',
  'GBP': '🇬🇧',
  'CNY': '🇨🇳',
  'THB': '🇹🇭',
  'KRW': '🇰🇷',
  'TWD': '🇹🇼',
  'SGD': '🇸🇬',
  'AUD': '🇦🇺',
  'HKD': '🇭🇰',
  'PHP': '🇵🇭',
  'VND': '🇻🇳',
  'IDR': '🇮🇩',
  'MYR': '🇲🇾',
  'INR': '🇮🇳',
  'CAD': '🇨🇦',
  'CHF': '🇨🇭',
  'SEK': '🇸🇪',
  'NOK': '🇳🇴',
  'DKK': '🇩🇰',
  'NZD': '🇳🇿',
  'ZAR': '🇿🇦',
  'BRL': '🇧🇷',
  'MXN': '🇲🇽',
  'TRY': '🇹🇷',
};

const _currencyLabels = {
  'USD': '米ドル',
  'EUR': 'ユーロ',
  'GBP': '英ポンド',
  'CNY': '中国元',
  'THB': 'タイバーツ',
  'KRW': '韓国ウォン',
  'TWD': '台湾ドル',
  'SGD': 'シンガポールドル',
  'AUD': '豪ドル',
  'HKD': '香港ドル',
  'PHP': 'フィリピンペソ',
  'VND': 'ベトナムドン',
  'IDR': 'インドネシアルピア',
  'MYR': 'マレーシアリンギット',
  'INR': 'インドルピー',
  'CAD': 'カナダドル',
  'CHF': 'スイスフラン',
  'SEK': 'スウェーデンクローナ',
  'NOK': 'ノルウェークローネ',
  'DKK': 'デンマーククローネ',
  'NZD': 'ニュージーランドドル',
  'ZAR': '南アフリカランド',
  'BRL': 'ブラジルレアル',
  'MXN': 'メキシコペソ',
  'TRY': 'トルコリラ',
};

class OverseasRateCard extends StatelessWidget {
  final String currency;
  final double rate;
  final CamillColors colors;

  const OverseasRateCard({
    super.key,
    required this.currency,
    required this.rate,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final flag = _currencyFlags[currency] ?? '🌐';
    final label = _currencyLabels[currency] ?? currency;

    String rateStr;
    if (rate == 0) {
      rateStr = '---';
    } else if (rate < 1) {
      rateStr = rate.toStringAsFixed(4);
    } else if (rate >= 100) {
      rateStr = rate.toStringAsFixed(1);
    } else {
      rateStr = rate.toStringAsFixed(2);
    }

    return CamillCard(
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label（$currency）',
                  style: camillBodyStyle(12, colors.textMuted),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '1 $currency  =  ',
                        style: camillBodyStyle(
                          13,
                          colors.textSecondary,
                          weight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '¥$rateStr',
                        style: camillAmountStyle(28, colors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
