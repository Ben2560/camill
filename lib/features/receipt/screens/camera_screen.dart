import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../services/receipt_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/loading_overlay.dart';

class CameraScreen extends StatefulWidget {
  final bool isCard;
  const CameraScreen({super.key, this.isCard = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  final _receiptService = ReceiptService();
  final _api = ApiService();
  bool _loading = false;
  int _analysisCount = 0;
  int _analysisLimit = 10;
  File? _pendingImage; // 確認待ちの画像（非nullのとき確認画面を表示）
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBillingStatus();
  }

  Future<void> _loadBillingStatus() async {
    try {
      final data = await _api.get('/billing/status');
      if (!mounted) return;
      setState(() {
        _analysisCount =
            (data['analysis_count_this_month'] as num?)?.toInt() ?? 0;
        _analysisLimit = (data['analysis_limit'] as num?)?.toInt() ?? 10;
      });
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1000,
    );
    if (picked == null) return;
    if (!mounted) return;
    final file = File(picked.path);

    if (source == ImageSource.gallery) {
      setState(() => _pendingImage = file);
      return;
    }

    await _analyzeImage(file);
  }

  Future<void> _analyzeImage(File imageFile) async {
    if (!mounted) return;
    setState(() {
      _pendingImage = null;
      _loading = true;
    });
    try {
      final analysis = await _receiptService.analyzeReceipt(imageFile);
      if (mounted) {
        context.push('/receipt-preview', extra: analysis);
      }
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final next = _dragOffset + d.delta.dy;
    setState(() => _dragOffset = next.clamp(0.0, double.infinity));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragOffset > 120 || (d.primaryVelocity ?? 0) > 600) {
      context.pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.isCard) {
      return _buildCardLayout(context, colors);
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text('レシート撮影', style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        message: 'レシートを解析中',
        subtitle: 'しばらくお待ちください…',
        child: _pendingImage != null ? _buildConfirmView(colors) : _buildCameraView(colors),
      ),
    );
  }

  Widget _buildCardLayout(BuildContext context, CamillColors colors) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.93,
        child: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Scaffold(
                backgroundColor: colors.background,
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.textMuted.withAlpha(80),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: colors.textSecondary),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Text(
                              'レシート撮影',
                              textAlign: TextAlign.center,
                              style: camillHeadingStyle(17, colors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LoadingOverlay(
                        isLoading: _loading,
                        message: 'レシートを解析中',
                        subtitle: 'しばらくお待ちください…',
                        child: _pendingImage != null
                            ? _buildConfirmView(colors)
                            : _buildCameraView(colors),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmView(CamillColors colors) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'この画像でよろしいですか？',
                  style: camillHeadingStyle(16, colors.textPrimary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_pendingImage!, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textMuted,
                    side: BorderSide(color: colors.textMuted),
                  ),
                  onPressed: () => setState(() => _pendingImage = null),
                  child: Text('選び直す', style: camillBodyStyle(15, colors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.fabIcon,
                  ),
                  onPressed: () => _analyzeImage(_pendingImage!),
                  child: Text('解析する', style: camillBodyStyle(15, colors.fabIcon)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView(CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.receipt_long, size: 80, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'レシートを撮影してください',
            textAlign: TextAlign.center,
            style: camillHeadingStyle(18, colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '品目・金額・クーポンを自動で読み取ります',
            textAlign: TextAlign.center,
            style: camillBodyStyle(13, colors.textMuted),
          ),
          const SizedBox(height: 16),
          _AnalysisBadge(
            count: _analysisCount,
            limit: _analysisLimit,
            colors: colors,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.fabIcon,
            ),
            onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
            icon: Icon(Icons.camera_alt, color: colors.fabIcon),
            label: Text('カメラで撮影', style: camillBodyStyle(16, colors.fabIcon)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
            ),
            onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
            icon: Icon(Icons.photo_library_outlined, color: colors.primary),
            label: Text('ギャラリーから選択', style: camillBodyStyle(16, colors.primary)),
          ),
          const SizedBox(height: 32),
          _Tips(colors: colors),
        ],
      ),
    );
  }
}

class _Tips extends StatelessWidget {
  final CamillColors colors;
  const _Tips({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '撮影のコツ',
            style: camillBodyStyle(14, colors.primary, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _TipRow(
            icon: Icons.wb_sunny_outlined,
            text: '明るい場所で撮影する',
            colors: colors,
          ),
          _TipRow(
            icon: Icons.straighten,
            text: 'レシート全体が写るようにする',
            colors: colors,
          ),
          _TipRow(
            icon: Icons.blur_off,
            text: 'ピントを合わせてブレないようにする',
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final int count;
  final int limit;
  final CamillColors colors;

  const _AnalysisBadge({
    required this.count,
    required this.limit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final atLimit = count >= limit;
    final nearLimit = count >= (limit * 0.8).floor();
    final badgeColor = atLimit
        ? colors.danger
        : nearLimit
        ? colors.danger
        : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withAlpha(80)),
      ),
      child: Text(
        '今月の解析 $count / $limit 回',
        style: TextStyle(
          fontSize: 12,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final CamillColors colors;

  const _TipRow({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(text, style: camillBodyStyle(13, colors.textPrimary)),
        ],
      ),
    );
  }
}
