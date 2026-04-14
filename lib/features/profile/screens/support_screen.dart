import 'package:flutter/material.dart';
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

  static const _categoryLabels = {
    'billing': '課金・プラン',
    'usage': '使い方',
    'bug': 'バグ・不具合',
    'other': 'その他',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('/users/inquiries');
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
        onSubmitted: () {
          _load();
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _inquiries.isEmpty
              ? _buildEmpty(colors)
              : _buildList(colors),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewInquiry,
        backgroundColor: colors.primary,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: Text('新しい問い合わせ',
            style: camillBodyStyle(14, Colors.white, weight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmpty(CamillColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.support_agent_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text('お問い合わせ履歴はありません',
              style: camillBodyStyle(15, colors.textSecondary)),
          const SizedBox(height: 6),
          Text('下のボタンから問い合わせを送信できます',
              style: camillBodyStyle(13, colors.textMuted)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildList(CamillColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _inquiries.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _InquiryCard(
        inquiry: _inquiries[i],
        categoryLabels: _categoryLabels,
        colors: colors,
      ),
    );
  }
}

// ── 問い合わせカード ─────────────────────────────────────────────────────────

class _InquiryCard extends StatefulWidget {
  final Map<String, dynamic> inquiry;
  final Map<String, String> categoryLabels;
  final CamillColors colors;

  const _InquiryCard({
    required this.inquiry,
    required this.categoryLabels,
    required this.colors,
  });

  @override
  State<_InquiryCard> createState() => _InquiryCardState();
}

class _InquiryCardState extends State<_InquiryCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // 返信があれば最初から展開
    _expanded = widget.inquiry['status'] == 'replied';
  }

  @override
  Widget build(BuildContext context) {
    final inq = widget.inquiry;
    final colors = widget.colors;
    final status = inq['status'] as String? ?? 'pending';
    final hasReply = status == 'replied' && inq['reply_text'] != null;
    final categoryKey = inq['category'] as String? ?? 'other';
    final categoryLabel =
        widget.categoryLabels[categoryKey] ?? categoryKey;

    final (statusLabel, statusColor) = switch (status) {
      'replied' => ('返信あり', colors.success),
      'closed' => ('完了', colors.textMuted),
      _ => ('返信待ち', colors.accent),
    };

    final createdAt = _formatDate(inq['created_at'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(categoryLabel,
                                  style: camillBodyStyle(
                                      11, colors.primary)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(statusLabel,
                                  style: camillBodyStyle(
                                      11, statusColor,
                                      weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          inq['subject'] as String? ?? '',
                          style: camillBodyStyle(14, colors.textPrimary,
                              weight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(createdAt,
                            style: camillBodyStyle(11, colors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // 展開コンテンツ
          if (_expanded) ...[
            Divider(height: 1, color: colors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('送信内容',
                  style: camillBodyStyle(11, colors.textMuted,
                      weight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(inq['body'] as String? ?? '',
                  style: camillBodyStyle(13, colors.textSecondary)),
            ),
            if (hasReply) ...[
              Divider(height: 1, color: colors.surfaceBorder),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.success.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.success.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent_outlined,
                            size: 14, color: colors.success),
                        const SizedBox(width: 4),
                        Text('サポートからの返信',
                            style: camillBodyStyle(11, colors.success,
                                weight: FontWeight.w600)),
                        const Spacer(),
                        Text(_formatDate(inq['replied_at'] as String?),
                            style: camillBodyStyle(10, colors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(inq['reply_text'] as String? ?? '',
                        style: camillBodyStyle(13, colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── 新規問い合わせシート ─────────────────────────────────────────────────────

class _NewInquirySheet extends StatefulWidget {
  final VoidCallback onSubmitted;

  const _NewInquirySheet({required this.onSubmitted});

  @override
  State<_NewInquirySheet> createState() => _NewInquirySheetState();
}

class _NewInquirySheetState extends State<_NewInquirySheet> {
  final _api = ApiService();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
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
      await _api.post('/users/inquiries', body: {
        'category': _category,
        'subject': subject,
        'body': body,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      showTopNotification(context, 'お問い合わせを送信しました。返信をお待ちください。');
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
          // ドラッグハンドル
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
          // カテゴリ
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
                      weight: selected ? FontWeight.w600 : FontWeight.normal,
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
          // 件名
          Text('件名',
              style: camillBodyStyle(12, colors.textMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectCtrl,
            maxLength: 100,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              counterStyle: camillBodyStyle(11, colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          // 内容
          Text('内容',
              style: camillBodyStyle(12, colors.textMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyCtrl,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
