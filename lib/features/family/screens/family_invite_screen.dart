import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/camill_colors.dart';
import '../../../shared/models/family_model.dart';

/// QRコードを表示して招待する画面
class FamilyInviteScreen extends StatelessWidget {
  final FamilyInvite invite;
  const FamilyInviteScreen({super.key, required this.invite});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roleLabel = invite.role == 'child' ? '子供' : '大人（パートナー）';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text('招待QRコード',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('このQRコードを読み取ってもらってください',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: invite.token,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(invite.role == 'child'
                      ? Icons.child_care_outlined
                      : Icons.person_outline,
                      color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(roleLabel,
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '有効期限: ${_formatExpiry(invite.expiresAt)}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}まで';
  }
}
