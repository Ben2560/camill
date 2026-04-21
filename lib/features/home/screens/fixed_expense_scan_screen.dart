import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/fixed_expense_model.dart';
import '../services/fixed_expense_service.dart';

class FixedExpenseScanScreen extends StatefulWidget {
  const FixedExpenseScanScreen({super.key});

  @override
  State<FixedExpenseScanScreen> createState() => _FixedExpenseScanScreenState();
}

class _FixedExpenseScanScreenState extends State<FixedExpenseScanScreen> {
  final _svc = FixedExpenseService();
  final _fmt = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

  bool _scanning = false;
  List<BankTransaction> _transactions = [];
  // 確認済みトランザクション（index → 確認済み）
  final Set<int> _confirmed = {};
  bool _scanned = false; // スキャン済みフラグ（空結果メッセージ表示用）

  static const _categoryLabels = {
    'housing': '住居費',
    'utility': '光熱費',
    'subscription': 'サブスク',
  };
  static const _categoryColors = AppConstants.categoryColors;

  Future<void> _pickAndScan() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _scanning = true;
      _transactions = [];
      _confirmed.clear();
    });

    try {
      final bytes =
          await FlutterImageCompress.compressWithFile(
            picked.path,
            minWidth: 1000,
            quality: 75,
          ) ??
          await File(picked.path).readAsBytes();

      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final result = await _svc.scanBankStatement(b64);
      setState(() {
        _transactions = result;
        _scanned = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解析に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _confirmTransaction(int index) async {
    final tx = _transactions[index];
    if (tx.matchedCategory == null) return;

    final ym = DateTime.now();
    final yearMonth = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';

    try {
      await _svc.markPaid(yearMonth, tx.matchedCategory!);
      setState(() => _confirmed.add(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登録に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '銀行明細で確認',
          style: camillBodyStyle(
            17,
            colors.textPrimary,
            weight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, _confirmed.isNotEmpty),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // 説明カード
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '銀行アプリの取引履歴画面のスクリーンショットを読み込むと、固定費の引き落とし状況を自動確認できます。',
                    style: camillBodyStyle(13, colors.primary),
                  ),
                ),
              ],
            ),
          ),

          // スキャンボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanning ? null : _pickAndScan,
              icon: _scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(_scanning ? '解析中...' : '明細スクショを選ぶ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_transactions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '検出された取引',
                style: camillBodyStyle(
                  13,
                  colors.textMuted,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            ..._transactions.asMap().entries.map(
              (e) => _buildTransactionTile(e.key, e.value, colors),
            ),

            if (_confirmed.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '完了（${_confirmed.length}件確認済み）',
                    style: camillBodyStyle(
                      15,
                      Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],

          if (!_scanning && _transactions.isEmpty && _scanned)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  '取引が見つかりませんでした',
                  style: camillBodyStyle(14, colors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    int index,
    BankTransaction tx,
    CamillColors colors,
  ) {
    final isConfirmed = _confirmed.contains(index);
    final hasMatch = tx.matchedCategory != null;
    final catLabel = _categoryLabels[tx.matchedCategory];
    final catColor = hasMatch
        ? (_categoryColors[tx.matchedCategory] ?? colors.primary)
        : colors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isConfirmed
              ? const Color(0xFF34C759).withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isConfirmed
                ? const Color(0xFF34C759).withValues(alpha: 0.4)
                : colors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: camillBodyStyle(
                      14,
                      colors.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        tx.date,
                        style: camillBodyStyle(12, colors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmt.format(tx.amount),
                        style: camillBodyStyle(
                          12,
                          colors.textSecondary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (hasMatch) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$catLabel と一致',
                        style: camillBodyStyle(
                          11,
                          catColor,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasMatch)
              isConfirmed
                  ? Icon(
                      Icons.check_circle,
                      color: const Color(0xFF34C759),
                      size: 28,
                    )
                  : GestureDetector(
                      onTap: () => _confirmTransaction(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '確認',
                          style: camillBodyStyle(
                            13,
                            Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
