import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/top_notification.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _inquiries = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await _api.getAny('/users/inquiries');
      if (!mounted) return;
      setState(() {
        _inquiries = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('inquiries load failed: $e');
    }
  }

  void _openNewInquiry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewInquirySheet(
        onSubmitted: (newInquiry) async {
          await _load();
          if (!mounted) return;
          final id = newInquiry['inquiry_id'] as String?;
          if (id == null) return;
          final found = _inquiries.firstWhere(
            (e) => e['inquiry_id'] == id,
            orElse: () => newInquiry,
          );
          context.push('/support/$id', extra: found);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('お問い合わせ',
            style: camillHeadingStyle(17, colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openNewInquiry,
            tooltip: '新しい問い合わせ',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        color: colors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _inquiries.isEmpty
                ? _buildEmpty(colors)
                : _buildList(colors),
      ),
    );
  }

  Widget _buildEmpty(CamillColors colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_outlined,
                  size: 36, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text('お問い合わせ履歴はありません',
                style: camillBodyStyle(15, colors.textSecondary)),
            const SizedBox(height: 6),
            Text('右上のボタンから問い合わせを送信できます',
                style: camillBodyStyle(13, colors.textMuted)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _openNewInquiry,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('問い合わせを送る'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildList(CamillColors colors) {
    return ListView.builder(
      itemCount: _inquiries.length,
      itemBuilder: (_, i) {
        final inq = _inquiries[i];
        final messages = (inq['messages'] as List?) ?? [];
        final lastMsg = messages.isNotEmpty
            ? messages.last as Map<String, dynamic>
            : null;
        final lastBody = lastMsg?['body'] as String? ??
            inq['body'] as String? ??
            '';
        final lastTime = _formatTime(
          lastMsg?['created_at'] as String? ??
              inq['created_at'] as String?,
        );
        final status = inq['status'] as String? ?? 'pending';
        final hasNewReply = status == 'replied';

        return Column(
          children: [
            InkWell(
              onTap: () => context.push(
                '/support/${inq['inquiry_id']}',
                extra: inq,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // アバター
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.support_agent_outlined,
                          size: 26, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    // コンテンツ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  inq['subject'] as String? ?? '',
                                  style: camillBodyStyle(
                                      15, colors.textPrimary,
                                      weight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(lastTime,
                                  style:
                                      camillBodyStyle(12, colors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastBody,
                                  style: camillBodyStyle(
                                      13, colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasNewReply) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.success,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('返信',
                                      style: camillBodyStyle(
                                          11, Colors.white,
                                          weight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // LINE風区切り線（左インデント）
            Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Divider(height: 1, color: colors.surfaceBorder),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}

// ── 新規問い合わせシート ─────────────────────────────────────────────────────

class _NewInquirySheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmitted;

  const _NewInquirySheet({required this.onSubmitted});

  @override
  State<_NewInquirySheet> createState() => _NewInquirySheetState();
}

class _NewInquirySheetState extends State<_NewInquirySheet> {
  final _api = ApiService();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  String _category = 'other';
  bool _sending = false;

  static const _categories = [
    ('billing', '課金・プラン'),
    ('usage', '使い方'),
    ('bug', 'バグ・不具合'),
    ('other', 'その他'),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      showTopNotification(context, '件名と内容を入力してください');
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await _api.post('/users/inquiries', body: {
        'category': _category,
        'subject': subject,
        'body': body,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      showTopNotification(context, 'お問い合わせを送信しました');
      await widget.onSubmitted(Map<String, dynamic>.from(result as Map));
    } catch (e) {
      if (!mounted) return;
      showTopNotification(context, '送信に失敗しました。時間をおいて再度お試しください。');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('新しい問い合わせ',
              style: camillHeadingStyle(17, colors.textPrimary)),
          const SizedBox(height: 16),
          Text('カテゴリ',
              style: camillBodyStyle(12, colors.textMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categories.map((entry) {
              final (key, label) = entry;
              final selected = _category == key;
              return ChoiceChip(
                label: Text(label,
                    style: camillBodyStyle(
                      13,
                      selected ? colors.primary : colors.textSecondary,
                      weight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    )),
                selected: selected,
                selectedColor: colors.primaryLight,
                backgroundColor: colors.background,
                side: BorderSide(
                  color: selected
                      ? colors.primary.withAlpha(80)
                      : colors.surfaceBorder,
                ),
                onSelected: (_) => setState(() => _category = key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('件名',
              style: camillBodyStyle(12, colors.textMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectCtrl,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _bodyFocus.requestFocus(),
            style: camillBodyStyle(14, colors.textPrimary),
            decoration: InputDecoration(
              hintText: '例: スキャン上限について',
              hintStyle: camillBodyStyle(14, colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.surfaceBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              counterStyle: camillBodyStyle(11, colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Text('内容',
              style: camillBodyStyle(12, colors.textMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyCtrl,
            focusNode: _bodyFocus,
            maxLines: 5,
            maxLength: 1000,
            style: camillBodyStyle(14, colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'お困りの内容を詳しく教えてください',
              hintStyle: camillBodyStyle(14, colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.surfaceBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              counterStyle: camillBodyStyle(11, colors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('送信する',
                      style: camillBodyStyle(15, Colors.white,
                          weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
