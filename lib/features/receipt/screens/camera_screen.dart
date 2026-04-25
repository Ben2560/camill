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
  final ImageSource? autoSource;
  final File? initialImage;
  final String? documentHint;
  const CameraScreen({
    super.key,
    this.autoSource,
    this.initialImage,
    this.documentHint,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  final _receiptService = ReceiptService();
  final _api = ApiService();
  bool _loading = false;
  bool _isPremium = false;
  int _analysisCount = 0;
  int _analysisLimit = 10;
  File? _pendingImage; // 確認待ちの画像（非nullのとき確認画面を表示）
  String _loadingSubtitle = 'しばらくお待ちください…';

  @override
  void initState() {
    super.initState();
    _loadBillingStatus();
    if (widget.initialImage != null) {
      _pendingImage = widget.initialImage;
    } else if (widget.autoSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(widget.autoSource!);
      });
    }
  }

  Future<void> _loadBillingStatus() async {
    try {
      final data = await _api.get('/billing/status');
      if (!mounted) return;
      setState(() {
        _analysisCount =
            (data['analysis_count_this_month'] as num?)?.toInt() ?? 0;
        _analysisLimit = (data['analysis_limit'] as num?)?.toInt() ?? 10;
        _isPremium = data['is_premium'] as bool? ?? false;
      });
    } catch (e) {
      debugPrint('billing status load failed: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1000,
    );
    if (picked == null) {
      // autoSource で自動起動して何も選ばなかった場合は戻る
      if (widget.autoSource != null && mounted) context.pop();
      return;
    }
    if (!mounted) return;
    final file = File(picked.path);

    if (source == ImageSource.gallery) {
      setState(() => _pendingImage = file);
      return;
    }

    await _analyzeImage(file);
  }

  String _errorMessage(Object e) {
    final s = e.toString();
    if (s.contains('429') || s.contains('上限')) {
      return '今月の解析上限に達しました。プランをアップグレードするか来月までお待ちください。';
    }
    if (s.contains('timeout') || s.contains('TimeoutException')) {
      return '解析がタイムアウトしました。通信環境を確認してもう一度お試しください。';
    }
    if (s.contains('SocketException') ||
        s.contains('network') ||
        s.contains('接続')) {
      return 'ネットワークに接続できませんでした。通信環境を確認してください。';
    }
    if (s.contains('401') || s.contains('403')) {
      return 'ログインの有効期限が切れました。再ログインしてください。';
    }
    if (s.contains('500') || s.contains('502') || s.contains('503')) {
      return 'サーバーでエラーが発生しました。しばらく待ってから再試行してください。';
    }
    return '解析に失敗しました: $s';
  }

  /// 自動リトライすべきエラーかどうかを判定。
  /// 上限超過・認証エラーはリトライしても意味がないので除外。
  bool _isRetryable(Object e) {
    final s = e.toString();
    if (s.contains('429') || s.contains('上限')) return false;
    if (s.contains('401') || s.contains('403')) return false;
    return true;
  }

  Future<void> _analyzeImage(File imageFile) async {
    if (!mounted) return;
    setState(() {
      _pendingImage = null;
      _loading = true;
      _loadingSubtitle = 'しばらくお待ちください…';
    });

    // widget.initialImage は呼び出し元が管理するため削除しない
    final isTempFile = imageFile.path != widget.initialImage?.path;

    const maxAttempts = 3;
    Object? lastError;

    try {
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          final analyses = await _receiptService.analyzeReceipt(
            imageFile,
            documentHint: widget.documentHint,
          );
          // 解析成功
          if (mounted) setState(() => _loading = false);
          final maxReceipts = _isPremium ? 5 : 1;
          if (mounted) {
            await context.push(
              '/receipt-preview',
              extra: (analyses: analyses, maxReceipts: maxReceipts),
            );
            // 保存せずに戻ってきた場合はカメラ画面も閉じる（保存時は context.go('/') でカメラも破棄される）
            if (mounted && context.canPop()) {
              context.pop();
            }
          }
          return;
        } catch (e) {
          lastError = e;
          final canRetry = _isRetryable(e) && attempt < maxAttempts;
          if (!canRetry) break;
          // リトライ前にメッセージを更新してバックオフ待機
          if (mounted) setState(() => _loadingSubtitle = 'もうしばらくお待ちください…');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    } finally {
      if (isTempFile && imageFile.existsSync()) imageFile.deleteSync();
    }

    // 全試行失敗
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(lastError!)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // autoSourceカメラ（透明）はエラー後に自分でpopして戻る
      if (widget.autoSource != null && context.canPop()) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAutoSource = widget.autoSource != null;
    // autoSourceのとき: 常に透明（ホーム等の画面が背景に透ける）
    // 確認画面でのみAppBarを表示、ゴースト/ローディング中はAppBarなし
    // extendBodyBehindAppBar=trueでBlurがステータスバー部分まで覆う（白ヘッダ防止）
    final showConfirmAppBar =
        isAutoSource && _pendingImage != null && !_loading;
    return Scaffold(
      // autoSource時: 確認画面のみ背景あり、ゴーストとローディング中は透明（ホーム画面が透ける）
      backgroundColor: (isAutoSource && _pendingImage == null)
          ? Colors.transparent
          : colors.background,
      extendBodyBehindAppBar: isAutoSource,
      appBar: isAutoSource
          ? (showConfirmAppBar
                ? AppBar(
                    backgroundColor: colors.background,
                    iconTheme: IconThemeData(color: colors.textSecondary),
                  )
                : null)
          : AppBar(
              backgroundColor: colors.background,
              iconTheme: IconThemeData(color: colors.textSecondary),
            ),
      body: LoadingOverlay(
        isLoading: _loading,
        message: '解析中',
        subtitle: _loadingSubtitle,
        blur: true,
        child: _loading
            ? const SizedBox.shrink()
            : _pendingImage != null
            ? _buildConfirmView(colors)
            : (isAutoSource
                  ? const SizedBox.shrink()
                  : _buildCameraView(colors)),
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
                  child: Text(
                    '選び直す',
                    style: camillBodyStyle(15, colors.textMuted),
                  ),
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
                  child: Text(
                    '解析する',
                    style: camillBodyStyle(15, colors.fabIcon),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView(CamillColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            switch (widget.documentHint) {
              'bill' => Icons.description_outlined,
              'medical' => Icons.medical_information_outlined,
              _ => Icons.receipt_long,
            },
            size: 80,
            color: colors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            switch (widget.documentHint) {
              'bill' => '請求書を撮影してください',
              'medical' => '医療明細を撮影してください',
              _ => 'レシートを撮影してください',
            },
            textAlign: TextAlign.center,
            style: camillHeadingStyle(18, colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            switch (widget.documentHint) {
              'bill' => '金額・支払期限を自動で読み取ります',
              'medical' => '診療内容・自己負担額を自動で読み取ります',
              _ => '品目・金額・クーポンを自動で読み取ります',
            },
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
            label: Text(
              'ギャラリーから選択',
              style: camillBodyStyle(16, colors.primary),
            ),
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
    final badgeColor = (atLimit || nearLimit)
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
