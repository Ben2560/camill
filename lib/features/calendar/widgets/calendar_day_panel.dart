import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/coupon_model.dart';
import '../../../shared/models/summary_model.dart';

class CalendarDayPanel extends StatelessWidget {
  final DateTime day;
  final List<RecentReceipt> receipts;
  final List<Coupon> activeCoupons;
  final List<Bill> dueBills;
  final bool loading;
  final NumberFormat fmt;
  final CamillColors colors;
  final void Function(RecentReceipt) onTapReceipt;
  final void Function(Coupon) onTapCoupon;
  final void Function(Bill) onTapBill;

  const CalendarDayPanel({
    super.key,
    required this.day,
    required this.receipts,
    required this.activeCoupons,
    required this.dueBills,
    required this.loading,
    required this.fmt,
    required this.colors,
    required this.onTapReceipt,
    required this.onTapCoupon,
    required this.onTapBill,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final vPad = screenH < 650 ? 8.0 : 12.0;
    return _buildColumn(context, vPad);
  }

  Widget _buildColumn(BuildContext context, double vPad) {
    final total = receipts.fold<int>(0, (s, r) => s + r.totalAmount);
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekdayLabel = weekdays[day.weekday % 7];
    final screenW = MediaQuery.sizeOf(context).width;
    final badgeSize = screenW < 390 ? 40.0 : 48.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, vPad, 16, vPad),
          child: Row(
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: camillBodyStyle(
                        20,
                        colors.primary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      weekdayLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.month}月${day.day}日',
                    style: camillBodyStyle(
                      15,
                      colors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$weekdayLabel曜日',
                    style: camillBodyStyle(12, colors.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              if (receipts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('合計', style: camillBodyStyle(10, colors.textMuted)),
                    Text(
                      fmt.format(total),
                      style: camillAmountStyle(15, colors.primary),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.surfaceBorder),
        if (loading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (activeCoupons.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 14,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSameDay(day, DateTime.now())
                              ? '今日使えるクーポン'
                              : 'この日に使えるクーポン',
                          style: camillBodyStyle(
                            12,
                            colors.accent,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...activeCoupons.map((c) {
                    final isFree = c.discountAmount == 0;
                    String? expiryText;
                    if (c.validUntil != null) {
                      expiryText =
                          '〜${c.validUntil!.month}/${c.validUntil!.day}';
                    }
                    return GestureDetector(
                      onTap: () => onTapCoupon(c),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isFree
                                    ? Icons.card_giftcard_outlined
                                    : Icons.local_offer_outlined,
                                size: 15,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.description,
                                      style: camillBodyStyle(
                                        13,
                                        colors.textPrimary,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                    if (c.storeName.isNotEmpty)
                                      Text(
                                        c.storeName,
                                        style: camillBodyStyle(
                                          11,
                                          colors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isFree ? '無料' : '${c.discountAmount}円引き',
                                    style: camillBodyStyle(
                                      13,
                                      colors.accent,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  if (expiryText != null)
                                    Text(
                                      expiryText,
                                      style: camillBodyStyle(
                                        10,
                                        colors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Divider(height: 1, color: colors.surfaceBorder),
                ],
                if (dueBills.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '支払期限の請求書',
                          style: camillBodyStyle(
                            12,
                            const Color(0xFFE53935),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: dueBills.map((b) {
                        final catColor =
                            AppConstants.categoryColors[b.category] ??
                            const Color(0xFF90A4AE);
                        final catLabel =
                            AppConstants.categoryLabels[b.category] ?? 'その他';
                        return GestureDetector(
                          onTap: () => onTapBill(b),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withAlpha(12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE53935).withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                  color: Color(0xFFE53935),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.title,
                                        style: camillBodyStyle(
                                          14,
                                          colors.textPrimary,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: catColor.withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              catLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: catColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  fmt.format(b.amount),
                                  style: camillAmountStyle(
                                    14,
                                    const Color(0xFFE53935),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Color(0xFFE53935),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(height: 1, color: colors.surfaceBorder),
                ],
                if (receipts.isEmpty && dueBills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'この日の記録はありません',
                      style: camillBodyStyle(14, colors.textMuted),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: receipts.map((r) {
                        final isFirst = receipts.first == r;
                        return Column(
                          children: [
                            if (!isFirst)
                              Divider(height: 1, color: colors.surfaceBorder),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_outlined,
                                  color: colors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                r.storeName,
                                style: camillBodyStyle(14, colors.textPrimary),
                              ),
                              subtitle: () {
                                final dt = DateTime.parse(
                                  r.purchasedAt,
                                ).toLocal();
                                if (dt.hour == 0 && dt.minute == 0) return null;
                                return Text(
                                  DateFormat('HH:mm').format(dt),
                                  style: camillBodyStyle(12, colors.textMuted),
                                );
                              }(),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fmt.format(r.totalAmount),
                                    style: camillAmountStyle(
                                      14,
                                      colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: colors.textMuted,
                                  ),
                                ],
                              ),
                              onTap: () => onTapReceipt(r),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
      ],
    );
  }
}
