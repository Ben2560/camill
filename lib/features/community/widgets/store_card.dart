import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/community_model.dart';

class StoreCard extends StatelessWidget {
  final CommunityStore store;
  final bool isHighlighted;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLockTap;
  final Future<void> Function(String couponId)? onReport;

  const StoreCard({
    super.key,
    required this.store,
    this.isHighlighted = false,
    this.isExpanded = false,
    required this.onTap,
    this.onLockTap,
    this.onReport,
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
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? colors.primary : colors.surfaceBorder,
            width: isHighlighted ? 2.0 : 1,
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
    final allExpired =
        store.coupons.isNotEmpty && store.coupons.every((c) => c.isExpired);
    final active = store.coupons.where((c) => !c.isExpired).toList();
    final expired = store.coupons.where((c) => c.isExpired).toList();

    return Opacity(
      opacity: allExpired ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: allExpired
                      ? colors.surfaceBorder
                      : colors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  color: allExpired ? colors.textMuted : colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                              allExpired
                                  ? colors.textMuted
                                  : colors.textPrimary,
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
                      _buildCouponPreview(colors, allExpired, active)
                    else
                      Text(
                        'クーポンあり',
                        style: camillBodyStyle(12, colors.textSecondary),
                      ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: isExpanded
                ? _buildInlineCouponList(colors, active, expired)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponPreview(
    CamillColors colors,
    bool allExpired,
    List<SharedCoupon> active,
  ) {
    if (allExpired) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, size: 13, color: colors.textMuted),
          const SizedBox(width: 4),
          Text('すべて終了しました', style: camillBodyStyle(12, colors.textMuted)),
        ],
      );
    }

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

  Widget _buildInlineCouponList(
    CamillColors colors,
    List<SharedCoupon> active,
    List<SharedCoupon> expired,
  ) {
    if (store.coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text('クーポンはありません', style: camillBodyStyle(12, colors.textMuted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 20, color: colors.surfaceBorder),
        ...active.map(
          (c) =>
              _InlineCouponRow(coupon: c, colors: colors, onReport: onReport),
        ),
        if (expired.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              '終了したクーポン',
              style: camillBodyStyle(
                11,
                colors.textMuted,
                weight: FontWeight.w600,
              ),
            ),
          ),
          ...expired.map(
            (c) =>
                _InlineCouponRow(coupon: c, colors: colors, onReport: onReport),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _InlineCouponRow extends StatelessWidget {
  final SharedCoupon coupon;
  final CamillColors colors;
  final Future<void> Function(String couponId)? onReport;

  const _InlineCouponRow({
    required this.coupon,
    required this.colors,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final expired = coupon.isExpired;
    final label = coupon.isFree
        ? '無料クーポン'
        : coupon.discountPercent != null
        ? '${coupon.discountPercent}%OFF'
        : '${coupon.discountAmount}円引き';

    String? dateLabel;
    if (coupon.validUntil != null) {
      final d = coupon.validUntil!;
      dateLabel = '〜${d.month}/${d.day}まで';
    }

    return Opacity(
      opacity: expired ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: expired
                    ? colors.surfaceBorder
                    : coupon.isFree
                    ? colors.accent.withAlpha(30)
                    : colors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  coupon.isFree ? '🎁' : '¥',
                  style: TextStyle(
                    fontSize: coupon.isFree ? 15 : 14,
                    color: expired ? colors.textMuted : colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.description,
                    style: camillBodyStyle(
                      12,
                      expired ? colors.textMuted : colors.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: expired
                              ? colors.surfaceBorder.withAlpha(80)
                              : colors.primaryLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          label,
                          style: camillBodyStyle(
                            11,
                            expired ? colors.textMuted : colors.primary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          dateLabel,
                          style: camillBodyStyle(10, colors.textMuted),
                        ),
                      ],
                      if (coupon.isExpiringSoon && !expired) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
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
                  ),
                ],
              ),
            ),
            if (onReport != null && !expired)
              GestureDetector(
                onTap: () => _confirmReport(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 15,
                    color: colors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmReport(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('不審なクーポンを報告'),
        content: const Text('このクーポンを虚偽・不審な情報として報告しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('報告する'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onReport!(coupon.couponId);
      }
    });
  }
}
