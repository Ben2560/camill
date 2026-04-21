import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/services/notification_inbox.dart';

class NotificationInboxSheet extends StatefulWidget {
  final CamillColors colors;
  const NotificationInboxSheet({super.key, required this.colors});

  @override
  State<NotificationInboxSheet> createState() => _NotificationInboxSheetState();
}

class _NotificationInboxSheetState extends State<NotificationInboxSheet> {
  late List<NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = NotificationInbox().getAll().toList();
  }

  Future<void> _clearAll() async {
    await NotificationInbox().clear();
    if (mounted) setState(() => _items = []);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Text(
                  '通知',
                  style: camillBodyStyle(
                    17,
                    c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_items.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      '全て削除',
                      style: camillBodyStyle(13, c.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.surfaceBorder),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: c.textMuted.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '通知はありません',
                          style: camillBodyStyle(14, c.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: c.surfaceBorder),
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.primaryLight.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 18,
                            color: c.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: camillBodyStyle(
                            14,
                            c.textPrimary,
                            weight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.body.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item.body,
                                  style: camillBodyStyle(12, c.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatTime(item.receivedAt),
                                style: camillBodyStyle(11, c.textMuted),
                              ),
                            ),
                          ],
                        ),
                        onTap: item.route != null
                            ? () {
                                Navigator.pop(context);
                                context.go(item.route!);
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${dt.month}/${dt.day}';
  }
}
