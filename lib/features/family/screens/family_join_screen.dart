import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/camill_colors.dart';
import '../services/family_service.dart';

class FamilyJoinScreen extends StatefulWidget {
  const FamilyJoinScreen({super.key});

  @override
  State<FamilyJoinScreen> createState() => _FamilyJoinScreenState();
}

class _FamilyJoinScreenState extends State<FamilyJoinScreen> {
  final _service = FamilyService();
  final _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ファミリーに参加しますか？'),
        content: const Text('スキャンしたQRコードでファミリーに参加します。'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('参加する')),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) {
      setState(() => _processing = false);
      await _controller.start();
      return;
    }

    try {
      // QRデータは "family_id|raw_token" 形式
      final parts = token.split('|');
      if (parts.length != 2) throw Exception('Invalid QR format');
      final family = await _service.joinFamily(parts[0], parts[1]);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${family.name} に参加しました')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('参加に失敗しました。QRコードを確認してください')));
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'QRコードをスキャン',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleScan),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: colors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: const Text(
              '招待QRコードを枠内に合わせてください',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
