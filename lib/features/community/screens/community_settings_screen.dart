import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/models/community_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/top_notification.dart' as notif;
import '../services/community_service.dart';

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _service = CommunityService();
  bool _loading = true;
  bool _saving = false;

  bool _shareEnabled = true;
  bool _notifyAll = true;
  List<String> _selectedStoreIds = [];
  List<String> _notifiedStoreIds = [];
  int _remainingChanges = 3;
  DateTime? _nextResetDate;
  bool _isPremium = false;

  // 近隣店舗（500m以内）
  List<CommunityStore> _nearbyStores = [];
  bool _locationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;
      setState(() {
        _shareEnabled = settings.shareEnabled;
        _notifyAll = settings.notifyAll;
        _selectedStoreIds = settings.selectedStoreIds;
        _notifiedStoreIds = settings.notifiedStoreIds;
        _remainingChanges = settings.remainingChanges;
        _nextResetDate = settings.nextResetDate;
        _isPremium = settings.isPremium;
        _loading = false;
      });
      // 設定取得後に近隣店舗を取得
      _loadNearbyStores();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadNearbyStores() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      // 位置情報権限を確認・取得
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationLoading = false;
          _locationError = '位置情報の権限がありません。設定から許可してください。';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final stores = await _service.fetchStores(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusM: 500,
      );

      if (!mounted) return;
      setState(() {
        _nearbyStores = stores;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = '近隣店舗の取得に失敗しました';
      });
    }
  }

  Future<void> _deselectStore(String storeId) async {
    setState(() => _saving = true);
    try {
      final newList = _selectedStoreIds.where((id) => id != storeId).toList();
      final settings = await _service.selectStores(newList);
      if (!mounted) return;
      setState(() {
        _selectedStoreIds = settings.selectedStoreIds;
        _remainingChanges = settings.remainingChanges;
        _nextResetDate = settings.nextResetDate;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      notif.showTopNotification(context, '店舗の解除に失敗しました');
    }
  }

  Future<void> _updateSetting({bool? shareEnabled, bool? notifyAll}) async {
    setState(() => _saving = true);
    try {
      final settings = await _service.updateSettings(
        shareEnabled: shareEnabled,
        notifyAll: notifyAll,
      );
      if (!mounted) return;
      setState(() {
        _shareEnabled = settings.shareEnabled;
        _notifyAll = settings.notifyAll;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      notif.showTopNotification(context, '設定の更新に失敗しました');
    }
  }

  Future<void> _toggleStoreNotification(String storeId, bool enabled) async {
    final newList = enabled
        ? [..._notifiedStoreIds, storeId]
        : _notifiedStoreIds.where((id) => id != storeId).toList();

    // 楽観的更新
    setState(() => _notifiedStoreIds = newList);

    try {
      final settings = await _service.updateSettings(notifiedStoreIds: newList);
      if (!mounted) return;
      setState(() => _notifiedStoreIds = settings.notifiedStoreIds);
    } catch (_) {
      // ロールバック
      if (!mounted) return;
      setState(
        () => _notifiedStoreIds = enabled
            ? newList.where((id) => id != storeId).toList()
            : [...newList, storeId],
      );
      notif.showTopNotification(context, '設定の更新に失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('コミュニティ設定'),
          backgroundColor: colors.background,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSection(colors, 'クーポンシェア', [
                    _buildSwitchTile(
                      colors,
                      icon: Icons.share_outlined,
                      title: 'クーポン情報をシェア',
                      subtitle: 'OCRで検出したクーポンを地域のユーザーと匿名で共有します',
                      value: _shareEnabled,
                      onChanged: (v) => _updateSetting(shareEnabled: v),
                    ),
                  ]),
                  _buildSection(colors, '通知', [
                    _buildSwitchTile(
                      colors,
                      icon: Icons.notifications_outlined,
                      title: '全クーポン通知',
                      subtitle: '近くの店舗に新しいクーポンが共有されたら通知',
                      value: _notifyAll,
                      onChanged: (v) => _updateSetting(notifyAll: v),
                    ),
                  ]),
                  _buildNearbyStoresSection(colors),
                  if (!_isPremium) _buildFreeStoreSelectionSection(colors),
                ],
              ),
      ),
    );
  }

  Widget _buildNearbyStoresSection(CamillColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Text(
                '近隣500m以内の店舗',
                style: camillBodyStyle(
                  12,
                  colors.textMuted,
                  weight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_locationLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                GestureDetector(
                  onTap: _loadNearbyStores,
                  child: Icon(Icons.refresh, size: 18, color: colors.primary),
                ),
            ],
          ),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              _locationError!,
              style: camillBodyStyle(13, colors.textMuted),
            ),
          )
        else if (_nearbyStores.isEmpty && !_locationLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '半径500m以内にクーポンのある店舗はありません',
              style: camillBodyStyle(13, colors.textMuted),
            ),
          )
        else
          ..._nearbyStores.map(
            (store) => _buildStoreNotificationTile(colors, store),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '特定の店舗のクーポン通知だけを受け取りたい場合は、全クーポン通知をOFFにして店舗ごとに設定してください。',
            style: camillBodyStyle(12, colors.textMuted),
          ),
        ),
        Divider(color: colors.surfaceBorder, height: 1),
      ],
    );
  }

  Widget _buildStoreNotificationTile(
    CamillColors colors,
    CommunityStore store,
  ) {
    final isNotified = _notifiedStoreIds.contains(store.storeId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.store_outlined, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName,
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'クーポン ${store.couponCount}件',
                  style: camillBodyStyle(12, colors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isNotified,
            onChanged: (v) => _toggleStoreNotification(store.storeId, v),
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeStoreSelectionSection(CamillColors colors) {
    return _buildSection(colors, '店舗選択（無料プラン）', [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '選択中の店舗: ${_selectedStoreIds.length}/2',
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '残り変更回数: $_remainingChanges回',
                  style: camillBodyStyle(13, colors.textSecondary),
                ),
              ],
            ),
            if (_nextResetDate != null) ...[
              const SizedBox(height: 2),
              Text(
                '次のリセット: ${_nextResetDate!.month}/${_nextResetDate!.day}',
                style: camillBodyStyle(12, colors.textMuted),
              ),
            ],
            const SizedBox(height: 12),
            if (_selectedStoreIds.isEmpty)
              Text(
                'コミュニティ画面でロックされた店舗をタップして選択できます。',
                style: camillBodyStyle(13, colors.textMuted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _selectedStoreIds.map((storeId) {
                  return Chip(
                    label: Text(
                      storeId,
                      style: camillBodyStyle(
                        13,
                        colors.primary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: colors.primaryLight,
                    deleteIcon: Icon(
                      Icons.close,
                      size: 14,
                      color: colors.primary,
                    ),
                    onDeleted: _remainingChanges > 0
                        ? () => _deselectStore(storeId)
                        : null,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Text(
              'コミュニティ画面でロックされた店舗をタップして追加・入れ替えができます。チップの×での解除も変更回数を1回消費します。3ヶ月に3回まで変更可能です。',
              style: camillBodyStyle(12, colors.textMuted),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSection(
    CamillColors colors,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: camillBodyStyle(
              12,
              colors.textMuted,
              weight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        Divider(color: colors.surfaceBorder, height: 1),
      ],
    );
  }

  Widget _buildSwitchTile(
    CamillColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: camillBodyStyle(
                    14,
                    colors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: camillBodyStyle(12, colors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
