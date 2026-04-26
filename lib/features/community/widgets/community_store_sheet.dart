import 'package:flutter/material.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/community_model.dart';

// ─── 店舗詳細シート ────────────────────────────────────────────────────────────

class StoreDetailSheet extends StatelessWidget {
  final CommunityStore store;
  final CamillColors colors;
  final VoidCallback? onLockTap;
  final Future<void> Function(String couponId)? onReport;

  const StoreDetailSheet({
    super.key,
    required this.store,
    required this.colors,
    this.onLockTap,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final active = store.coupons.where((c) => !c.isExpired).toList();
    final expired = store.coupons.where((c) => c.isExpired).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // 店舗ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: store.isLocked
                        ? colors.textMuted.withAlpha(20)
                        : colors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    store.isLocked ? Icons.lock_outline : Icons.store,
                    color: store.isLocked ? colors.textMuted : colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (store.isFeatured && !store.isLocked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              store.storeName,
                              style: camillBodyStyle(
                                16,
                                colors.textPrimary,
                                weight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (store.storeAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          store.storeAddress!,
                          style: camillBodyStyle(12, colors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!store.isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${store.couponCount}件',
                      style: camillBodyStyle(
                        12,
                        colors.primary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.surfaceBorder),
          // クーポン一覧 or ロック
          if (store.isLocked)
            _buildLockedBody(context, colors)
          else
            _buildCouponList(context, colors, active, expired),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildLockedBody(BuildContext context, CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 40, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'このお店のクーポンを見るには\n店舗を選択するか、プレミアムプランが必要です',
            style: camillBodyStyle(13, colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onLockTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '店舗を選択する',
                style: camillBodyStyle(
                  14,
                  Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(
    BuildContext context,
    CamillColors colors,
    List<SharedCoupon> active,
    List<SharedCoupon> expired,
  ) {
    if (store.coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text('クーポンはありません', style: camillBodyStyle(13, colors.textMuted)),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...active.map(
          (c) => CouponRow(coupon: c, colors: colors, onReport: onReport),
        ),
        if (expired.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
            (c) => CouponRow(coupon: c, colors: colors, onReport: onReport),
          ),
        ],
      ],
    );
  }
}

class CouponRow extends StatelessWidget {
  final SharedCoupon coupon;
  final CamillColors colors;
  final Future<void> Function(String couponId)? onReport;

  const CouponRow({
    super.key,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: expired
                    ? colors.surfaceBorder
                    : coupon.isFree
                    ? colors.accent.withAlpha(30)
                    : colors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  coupon.isFree ? '🎁' : '¥',
                  style: TextStyle(
                    fontSize: coupon.isFree ? 16 : 14,
                    color: expired ? colors.textMuted : colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.description,
                    style: camillBodyStyle(
                      13,
                      expired ? colors.textMuted : colors.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        label,
                        style: camillBodyStyle(
                          12,
                          expired ? colors.textMuted : colors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          dateLabel,
                          style: camillBodyStyle(11, colors.textMuted),
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
            if (onReport != null)
              GestureDetector(
                onTap: () => _confirmReport(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 16,
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
    final navigator = Navigator.of(context);
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
        navigator.pop();
        onReport!(coupon.couponId);
      }
    });
  }
}
