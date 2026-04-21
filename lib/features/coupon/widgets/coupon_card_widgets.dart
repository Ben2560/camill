import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';

const _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool dimmed;
  final VoidCallback onTap;

  const CouponCard({
    super.key,
    required this.coupon,
    this.dimmed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: coupon.isFree && !dimmed
            ? FreeCard(coupon: coupon)
            : RegularCard(coupon: coupon, colors: colors, dimmed: dimmed),
      ),
    );
  }
}

// ── 無料クーポン（ゴールドカード）────────────────────────────────────────────
class FreeCard extends StatelessWidget {
  final Coupon coupon;
  const FreeCard({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B6914), Color(0xFFD4A017), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      coupon.storeName,
                      style: camillBodyStyle(13, Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '無料クーポン',
                        style: camillBodyStyle(
                          10,
                          Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: camillBodyStyle(
                    16,
                    Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 28,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '無料',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (coupon.availableDays != null &&
                        coupon.availableDays!.isNotEmpty)
                      DayDotsSmall(availableDays: coupon.availableDays!),
                  ],
                ),
                if (coupon.validUntil != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        coupon.isExpired
                            ? Icons.cancel_outlined
                            : coupon.isExpiringSoon
                            ? Icons.warning_amber_outlined
                            : Icons.schedule,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _validityText(coupon),
                        style: camillBodyStyle(11, Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 通常クーポンカード ───────────────────────────────────────────────────────
class RegularCard extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final bool dimmed;

  const RegularCard({
    super.key,
    required this.coupon,
    required this.colors,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final expired = coupon.isExpired;
    final expiringSoon = coupon.isExpiringSoon;

    Color borderColor = colors.surfaceBorder;
    if (expiringSoon && !dimmed) borderColor = colors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: expiringSoon && !dimmed ? 1.5 : 1,
        ),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store_outlined, size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  coupon.storeName,
                  style: camillBodyStyle(13, colors.textMuted),
                ),
                const SizedBox(width: 6),
                if (coupon.isFromOcr)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OCR自動',
                      style: camillBodyStyle(9, colors.primary),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '手動',
                      style: camillBodyStyle(9, colors.textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              coupon.description,
              style: camillBodyStyle(
                15,
                colors.textPrimary,
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  coupon.discountAmount > 0
                      ? '${coupon.discountAmount}円引き'
                      : '無料',
                  style: camillAmountStyle(20, colors.primary),
                ),
                const Spacer(),
                if (coupon.availableDays != null &&
                    coupon.availableDays!.isNotEmpty)
                  DayDotsSmall(availableDays: coupon.availableDays!),
              ],
            ),
            if (coupon.validUntil != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    expired
                        ? Icons.cancel_outlined
                        : expiringSoon
                        ? Icons.warning_amber_outlined
                        : Icons.schedule,
                    size: 13,
                    color: expired || expiringSoon
                        ? colors.danger
                        : colors.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _validityText(coupon),
                    style: camillBodyStyle(
                      12,
                      expired || expiringSoon
                          ? colors.danger
                          : colors.textMuted,
                      weight: expiringSoon
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _validityText(Coupon coupon) {
  final from = coupon.validFrom;
  final until = coupon.validUntil;
  final days = coupon.daysUntilExpiry;
  final expired = coupon.isExpired;

  String range = '';
  if (from != null && until != null) {
    range = '${from.month}/${from.day}〜${until.month}/${until.day}  ';
  }

  if (expired) return '$range期限切れ';
  if (days != null) return '$range残り$days日';
  return range.trim();
}

// ── 曜日ドット（カード内小表示）────────────────────────────────────────────
class DayDotsSmall extends StatelessWidget {
  final List<int> availableDays;
  const DayDotsSmall({super.key, required this.availableDays});

  @override
  Widget build(BuildContext context) {
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final isAvailable = availableDays.contains(i);
        final isToday = i == todayIdx;
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable
                ? isToday
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFF4CAF50).withAlpha(180)
                : Colors.transparent,
            border: isAvailable
                ? null
                : Border.all(color: Colors.grey.withAlpha(80), width: 1),
          ),
          child: Center(
            child: Text(
              _dayLabels[i],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 曜日ピッカー（追加・編集ダイアログ用）──────────────────────────────────
class DayPicker extends StatelessWidget {
  final List<int> selected;
  final CamillColors colors;
  final ValueChanged<List<int>> onChanged;

  const DayPicker({
    super.key,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isSelected = selected.contains(i);
        return GestureDetector(
          onTap: () {
            final next = List<int>.from(selected);
            isSelected ? next.remove(i) : next.add(i);
            onChanged(next);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.primary : colors.surfaceBorder,
            ),
            child: Center(
              child: Text(
                _dayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.fabIcon : colors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final CamillColors colors;
  final VoidCallback onTap;

  const SortButton({
    super.key,
    required this.label,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.surfaceBorder,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: camillBodyStyle(
            12,
            active ? colors.fabIcon : colors.textMuted,
            weight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
