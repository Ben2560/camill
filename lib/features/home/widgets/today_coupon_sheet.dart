import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/coupon_model.dart';

class TodayCouponSheet extends StatelessWidget {
  final List<Coupon> coupons;
  final CamillColors colors;
  final ValueChanged<Coupon> onUsed;
  final VoidCallback onViewAll;

  const TodayCouponSheet({
    super.key,
    required this.coupons,
    required this.colors,
    required this.onUsed,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFD4A017),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日使えるクーポン',
                  style: camillHeadingStyle(16, colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = coupons[i];
                return _CouponRow(
                  coupon: c,
                  colors: colors,
                  onUsed: () => onUsed(c),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onViewAll,
                child: Text(
                  'クーポン財布をすべて見る',
                  style: camillBodyStyle(14, colors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final VoidCallback onUsed;

  const _CouponRow({
    required this.coupon,
    required this.colors,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    return coupon.isFree
        ? _FreeCouponCard(coupon: coupon, onUsed: onUsed)
        : _DiscountCouponCard(coupon: coupon, colors: colors, onUsed: onUsed);
  }
}

class _FreeCouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onUsed;
  const _FreeCouponCard({required this.coupon, required this.onUsed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '無料',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onUsed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
                        child: const Text(
                          '使用済みにする',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (coupon.validUntil != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        coupon.daysUntilExpiry == 0
                            ? '本日まで！'
                            : '残り${coupon.daysUntilExpiry}日',
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

class _DiscountCouponCard extends StatelessWidget {
  final Coupon coupon;
  final CamillColors colors;
  final VoidCallback onUsed;
  const _DiscountCouponCard({
    required this.coupon,
    required this.colors,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_offer_outlined,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.storeName,
                  style: camillBodyStyle(11, colors.textMuted),
                ),
                Text(
                  coupon.description,
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.bold,
                  ),
                ),
                if (coupon.validFrom != null && coupon.validUntil != null)
                  Text(
                    '${coupon.validFrom!.month}/${coupon.validFrom!.day}〜${coupon.validUntil!.month}/${coupon.validUntil!.day}',
                    style: camillBodyStyle(11, colors.textMuted),
                  )
                else if (coupon.validUntil != null)
                  Text(
                    coupon.daysUntilExpiry == 0
                        ? '本日まで！'
                        : '残り${coupon.daysUntilExpiry}日',
                    style: camillBodyStyle(11, colors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${coupon.discountAmount}円引き',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onUsed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '使用済みにする',
                    style: camillBodyStyle(
                      12,
                      Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
