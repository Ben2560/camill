import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/widgets/top_notification.dart';

class SupportDetailScreen extends StatefulWidget {
  final String inquiryId;
  final Map<String, dynamic> initialInquiry;

  const SupportDetailScreen({
    super.key,
    required this.inquiryId,
    required this.initialInquiry,
  });

  @override
  State<SupportDetailScreen> createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends State<SupportDetailScreen> {
  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;
  StreamSubscription<RemoteMessage>? _fcmSub;

  Map<String, dynamic> _inquiry = {};
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _inquiry = Map.from(widget.initialInquiry);
    _messages = List<Map<String, dynamic>>.from(
      (_inquiry['messages'] as List?) ?? [],
    );
    _initialLoaded = _messages.isNotEmpty;

    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(silent: true),
    );

    // FCMフォアグラウンド受信で即リロード
    _fcmSub = NotificationService().onForegroundMessage.stream.listen((msg) {
      if (msg.data['type'] == 'inquiry_reply' &&
          msg.data['inquiry_id'] == widget.inquiryId) {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _fcmSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final data = await _api.getAny('/users/inquiries');
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data as List);
      final found = list.firstWhere(
        (e) => e['inquiry_id'] == widget.inquiryId,
        orElse: () => _inquiry,
      );
      final wasAtBottom = _isAtBottom();
      setState(() {
        _inquiry = found;
        _messages = List<Map<String, dynamic>>.from(
          (found['messages'] as List?) ?? [],
        );
        _initialLoaded = true;
      });
      if (wasAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: !silent),
        );
      }
    } catch (e) {
      debugPrint('support detail load failed: $e');
      if (mounted && !_initialLoaded) {
        setState(() => _initialLoaded = true);
      }
    }
  }

  bool _isAtBottom() {
    if (!_scrollCtrl.hasClients) return true;
    final pos = _scrollCtrl.position;
    return pos.pixels >= pos.maxScrollExtent - 80;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      await _api.post(
        '/users/inquiries/${widget.inquiryId}/messages',
        body: {'body': body},
      );
      _msgCtrl.clear();
      await _load(silent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      showTopNotification(context, '送信に失敗しました');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = _inquiry['status'] as String? ?? 'pending';
    final subject =
        _inquiry['subject'] as String? ??
        widget.initialInquiry['subject'] as String? ??
        '';
    final canReply = status != 'closed';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          subject,
          style: camillHeadingStyle(16, colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: !_initialLoaded
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'メッセージがありません',
                      style: camillBodyStyle(14, Colors.white70),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final prev = i > 0 ? _messages[i - 1] : null;
                      return Column(
                        children: [
                          if (_shouldShowDate(prev, msg))
                            _DateDivider(isoDate: msg['created_at'] as String?),
                          _MessageBubble(message: msg, colors: colors),
                        ],
                      );
                    },
                  ),
          ),
          if (canReply)
            _InputBar(
              controller: _msgCtrl,
              sending: _sending,
              onSend: _send,
              colors: colors,
            ),
        ],
      ),
    );
  }

  bool _shouldShowDate(Map<String, dynamic>? prev, Map<String, dynamic> curr) {
    if (prev == null) return true;
    try {
      final prevDt = DateTime.parse(prev['created_at'] as String).toLocal();
      final currDt = DateTime.parse(curr['created_at'] as String).toLocal();
      return prevDt.year != currDt.year ||
          prevDt.month != currDt.month ||
          prevDt.day != currDt.day;
    } catch (_) {
      return false;
    }
  }
}

// ── メッセージバブル ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final CamillColors colors;

  const _MessageBubble({required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isUser = (message['sender'] as String?) == 'user';
    final body = message['body'] as String? ?? '';
    final imageDataUri = message['image_data'] as String?;
    final timeStr = _formatTime(message['created_at'] as String?);

    // base64 data URI → Uint8List
    Uint8List? imageBytes;
    if (imageDataUri != null && imageDataUri.isNotEmpty) {
      try {
        final comma = imageDataUri.indexOf(',');
        final b64 = comma >= 0
            ? imageDataUri.substring(comma + 1)
            : imageDataUri;
        imageBytes = base64Decode(b64);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // サポートアバター
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_outlined,
                size: 17,
                color: colors.primary,
              ),
            ),
          ],
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(timeStr, style: camillBodyStyle(10, Colors.white70)),
            ),
          // バブル
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 画像（添付がある場合）
                    if (imageBytes != null)
                      Image.memory(imageBytes, fit: BoxFit.cover),
                    // テキスト本文
                    if (body.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: isUser ? colors.primary : Colors.white,
                        child: Text(
                          body,
                          style: camillBodyStyle(
                            14,
                            isUser ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    // 画像のみでテキストなしの場合の背景
                    if (imageBytes != null && body.isEmpty)
                      Container(
                        color: isUser ? colors.primary : Colors.white,
                        height: 4,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(timeStr, style: camillBodyStyle(10, Colors.white70)),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── 日付区切り ───────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final String? isoDate;

  const _DateDivider({this.isoDate});

  @override
  Widget build(BuildContext context) {
    String label = '';
    if (isoDate != null) {
      try {
        final dt = DateTime.parse(isoDate!).toLocal();
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          label = '今日';
        } else if (dt.year == now.year) {
          label = '${dt.month}月${dt.day}日';
        } else {
          label = '${dt.year}年${dt.month}月${dt.day}日';
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: camillBodyStyle(12, Colors.white, weight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ── 入力バー ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final CamillColors colors;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: camillBodyStyle(15, colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'メッセージを入力',
                hintStyle: camillBodyStyle(15, colors.textMuted),
                filled: true,
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            height: 44,
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: Icon(
                      Icons.send_rounded,
                      color: colors.primary,
                      size: 26,
                    ),
                    tooltip: '送信',
                  ),
          ),
        ],
      ),
    );
  }
}
