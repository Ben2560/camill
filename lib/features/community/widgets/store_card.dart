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
        child: store.isLocked
            ? _buildLockedContent(colors)
            : _buildContent(colors),
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
                style: camillBodyStyle(
                  14,
                  colors.textMuted,
                  weight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              const SizedBox(height: 2),
              Text(
                'タップしてプランを確認',
                style: camillBodyStyle(
                  12,
                  colors.primary,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
      ],
    );
  }

  Widget _buildContent(CamillColors colors) {
    // 有効なクーポンが1枚もない場合（全部期限切れ）
    final allExpired =
        store.coupons.isNotEmpty && store.coupons.every((c) => c.isExpired);

    return Opacity(
      opacity: allExpired ? 0.5 : 1.0,
      child: Row(
        children: [
          // 店舗アイコン
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: allExpired ? colors.surfaceBorder : colors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.store,
              color: allExpired ? colors.textMuted : colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 店舗情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (store.isFeatured && !allExpired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '\u{1F525}',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        store.storeName,
                        style: camillBodyStyle(
                          14,
                          allExpired ? colors.textMuted : colors.textPrimary,
                          weight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                if (store.storeAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    store.storeAddress!,
                    style: camillBodyStyle(11, colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                if (store.coupons.isNotEmpty)
                  _buildCouponPreview(colors, allExpired)
                else
                  Text(
                    'クーポンあり',
                    style: camillBodyStyle(12, colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponPreview(CamillColors colors, bool allExpired) {
    if (allExpired) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, size: 13, color: colors.textMuted),
          const SizedBox(width: 4),
          Text('すべて終了しました', style: camillBodyStyle(12, colors.textMuted)),
        ],
      );
    }

    // 有効なクーポンのうち最良のものを表示
    final active = store.coupons.where((c) => !c.isExpired).toList();
    if (active.isEmpty) {
      return Text('クーポンあり', style: camillBodyStyle(12, colors.textSecondary));
    }
    final coupon = active.first;
    return Row(
      children: [
        Text(
          coupon.isFree ? '無料クーポン' : '${coupon.discountAmount}円引き',
          style: camillBodyStyle(12, colors.primary, weight: FontWeight.w600),
        ),
        if (active.length > 1) ...[
          const SizedBox(width: 4),
          Text(
            '他${active.length - 1}件',
            style: camillBodyStyle(11, colors.textSecondary),
          ),
        ],
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
              style: camillBodyStyle(
                10,
                colors.danger,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
