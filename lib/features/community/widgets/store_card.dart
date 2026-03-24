import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/community_model.dart';

class StoreCard extends StatelessWidget {
  final CommunityStore store;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback? onLockTap;

  const StoreCard({
    super.key,
    required this.store,
    this.isHighlighted = false,
    required this.onTap,
    this.onLockTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: store.isLocked ? onLockTap : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted ? colors.primaryLight : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? colors.primary : colors.surfaceBorder,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: store.isLocked ? _buildLockedContent(colors) : _buildContent(colors),
      ),
    );
  }

  Widget _buildLockedContent(CamillColors colors) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.textMuted.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.lock_outline, color: colors.textMuted, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.storeName,
                style: camillBodyStyle(14, colors.textMuted, weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              const SizedBox(height: 2),
              Text(
                'タップしてプランを確認',
                style: camillBodyStyle(12, colors.primary, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
      ],
    );
  }

  Widget _buildContent(CamillColors colors) {
    return Row(
      children: [
        // 店舗アイコン
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.store, color: colors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        // 店舗情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (store.isFeatured) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\u{1F525}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      store.storeName,
                      style: camillBodyStyle(14, colors.textPrimary, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (store.coupons.isNotEmpty)
                _buildCouponPreview(colors)
              else
                Text(
                  'クーポンあり',
                  style: camillBodyStyle(12, colors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCouponPreview(CamillColors colors) {
    final coupon = store.coupons.first;
    final isExpired = coupon.isExpired;
    return Row(
      children: [
        if (isExpired)
          Text(
            '終了しました',
            style: camillBodyStyle(12, colors.textMuted),
          )
        else ...[
          Text(
            coupon.isFree
                ? '無料クーポン'
                : '${coupon.discountAmount}円引き',
            style: camillBodyStyle(12, colors.primary, weight: FontWeight.w600),
          ),
          if (coupon.isExpiringSoon) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: colors.danger.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'まもなく終了',
                style: camillBodyStyle(10, colors.danger, weight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
