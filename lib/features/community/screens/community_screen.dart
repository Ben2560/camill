import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/community_model.dart';
import '../../../shared/services/api_service.dart';
import '../services/community_service.dart';
import '../widgets/map_styles.dart';
import '../widgets/store_card.dart';
import '../widgets/community_store_sheet.dart';

/// 最小ズームレベル（これ以上ズームアウトするとフェッチしない）
const _minFetchZoom = 13.0;

/// デフォルト位置（東京駅）
const _defaultLatLng = LatLng(35.6812, 139.7671);

class CommunityScreen extends ConsumerStatefulWidget {
  final String? focusStoreId;

  const CommunityScreen({super.key, this.focusStoreId});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _communityService = CommunityService();
  GoogleMapController? _mapController;
  final _sheetController = DraggableScrollableController();
  final _listScrollController = ScrollController();

  List<CommunityStore> _stores = [];
  Set<Marker> _markers = {};
  bool _loading = true;
  String? _error;
  LatLng _currentCenter = _defaultLatLng;
  double _currentZoom = 14.0;
  String? _highlightedStoreId;
  bool _locationPermissionGranted = false;
  Timer? _debounceTimer;
  bool _suppressCameraFetch = false; // プログラム的なカメラ移動時にフェッチを抑制
  double _sheetSize = 0.38;
  late ValueNotifier<String> _mapStyleNotifier;
  CommunitySettings? _settings;

  // 検索フィルター状態
  bool _filterFree = false;
  int? _minDiscountAmount; // null = フィルターなし（円単位）
  bool _searchPanelOpen = false;
  double _sliderValue = 0;

  List<CommunityStore> get _filteredStores {
    if (!_filterFree && _minDiscountAmount == null) return _stores;
    return _stores.where((store) {
      if (store.coupons.isEmpty) return false;
      if (_filterFree) {
        return store.coupons.any((c) => c.isFree && !c.isExpired);
      }
      if (_minDiscountAmount != null) {
        return store.coupons.any(
          (c) =>
              !c.isFree &&
              !c.isExpired &&
              c.discountAmount >= _minDiscountAmount!,
        );
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _mapStyleNotifier = ValueNotifier(
      communityMapStyle(ref.read(themeProvider).isDarkNow),
    );
    _sheetController.addListener(_onSheetSizeChanged);
    _initLocation();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _communityService.fetchSettings();
      if (!mounted) return;
      setState(() => _settings = settings);
    } catch (_) {}
  }

  void _onSheetSizeChanged() {
    if (_sheetController.isAttached) {
      setState(() => _sheetSize = _sheetController.size);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    _mapStyleNotifier.dispose();
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (!mounted) return;
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          // GPS不許可 → デフォルト位置で表示
          _fetchStores();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _fetchStores();
        return;
      }

      _locationPermissionGranted = true;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentCenter));
      _fetchStores();
    } catch (_) {
      if (!mounted) return;
      _fetchStores();
    }
  }

  Future<void> _fetchStores() async {
    if (!mounted) return;
    if (_currentZoom < _minFetchZoom) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stores = await _communityService.fetchStores(
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
      );
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _loading = false;
        _buildMarkers();
      });

      // 通知タップからの起動時、対象店舗をフォーカス
      if (widget.focusStoreId != null) {
        _focusStore(widget.focusStoreId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'データの取得に失敗しました';
        _loading = false;
      });
    }
  }

  void _buildMarkers() {
    final colors = ref.read(themeProvider).colors;

    _markers = _stores.map((store) {
      return Marker(
        markerId: MarkerId(store.storeId),
        position: LatLng(store.latitude, store.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          store.isFeatured
              ? BitmapDescriptor.hueOrange
              : (colors.isDark
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueAzure),
        ),
        onTap: () => _onPinTap(store),
      );
    }).toSet();
  }

  void _onPinTap(CommunityStore store) {
    setState(() => _highlightedStoreId = store.storeId);
    _showStoreDetailSheet(store);
  }

  void _showStoreDetailSheet(CommunityStore store) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoreDetailSheet(
        store: store,
        colors: colors,
        onLockTap: store.isLocked
            ? () {
                Navigator.pop(context);
                _onLockedStoreTap(store);
              }
            : null,
      ),
    );
  }

  void _onCardTap(CommunityStore store) {
    setState(() => _highlightedStoreId = store.storeId);
    _suppressCameraFetch = true;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(store.latitude, store.longitude), 16.0),
    );
  }

  void _focusStore(String storeId) {
    final store = _stores.where((s) => s.storeId == storeId).firstOrNull;
    if (store != null) {
      _onCardTap(store);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
    _currentZoom = position.zoom;
  }

  void _cycleSheetSize() {
    final current = _sheetController.size;
    final middle = _searchPanelOpen ? 0.55 : 0.38;
    double next;
    if (current < 0.2) {
      next = middle; // しまう → マニュアル
    } else if (current < 0.7) {
      next = 0.93; // マニュアル → フル画面
    } else {
      next = middle; // フル画面 → マニュアル
    }
    _sheetController.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onCameraIdle() {
    if (_suppressCameraFetch) {
      _suppressCameraFetch = false;
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_currentZoom >= _minFetchZoom) {
        _fetchStores();
      }
    });
  }

  Future<void> _onLockedStoreTap(CommunityStore store) async {
    final colors = context.colors;
    final settings = _settings;

    // 設定未取得なら再試行してから表示
    if (settings == null) {
      await _loadSettings();
      if (!mounted) return;
      if (_settings == null) {
        _showUpgradeDialog(colors);
        return;
      }
    }
    final s = _settings!;

    if (s.remainingChanges <= 0) {
      // 変更回数なし → 残り変更不可を案内しプランへ誘導
      _showNoChangesDialog(colors, s);
      return;
    }

    final selected = List<String>.from(s.selectedStoreIds);

    if (selected.length < 2) {
      // 1枠空きあり → 確認して追加
      _showSelectConfirmDialog(colors, store, selected, s.remainingChanges);
    } else {
      // 2枠埋まっている → 入れ替え先を選択
      _showReplaceDialog(colors, store, selected, s.remainingChanges);
    }
  }

  void _showNoChangesDialog(CamillColors colors, CommunitySettings settings) {
    final resetText = settings.nextResetDate != null
        ? '次のリセット: ${settings.nextResetDate!.month}/${settings.nextResetDate!.day}'
        : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '店舗変更回数の上限です',
          style: camillBodyStyle(
            17,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          '3ヶ月に3回まで変更できます。$resetText\n\nプレミアムプランにアップグレードすると全店舗を制限なく閲覧できます。',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('閉じる', style: camillBodyStyle(14, colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/plan');
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  void _showSelectConfirmDialog(
    CamillColors colors,
    CommunityStore store,
    List<String> currentSelected,
    int remainingChanges,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'この店舗を選択しますか？',
          style: camillBodyStyle(
            17,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.storeName,
              style: camillBodyStyle(
                15,
                colors.primary,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '選択するとクーポン詳細を閲覧できます。\n残り変更回数: $remainingChanges回',
              style: camillBodyStyle(13, colors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('キャンセル', style: camillBodyStyle(14, colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _applySelectStores([...currentSelected, store.storeId]);
            },
            child: const Text('選択する'),
          ),
        ],
      ),
    );
  }

  void _showReplaceDialog(
    CamillColors colors,
    CommunityStore store,
    List<String> currentSelected,
    int remainingChanges,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '入れ替える店舗を選んでください',
              style: camillBodyStyle(
                16,
                colors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '「${store.storeName}」を選択するため、現在の選択から1つ解除します。\n残り変更回数: $remainingChanges回',
              style: camillBodyStyle(13, colors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...currentSelected.map(
              (existingId) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final newList =
                        currentSelected.where((id) => id != existingId).toList()
                          ..add(store.storeId);
                    await _applySelectStores(newList);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            existingId,
                            style: camillBodyStyle(14, colors.textPrimary),
                          ),
                        ),
                        Icon(Icons.swap_horiz, size: 18, color: colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/plan');
                },
                child: const Text('プレミアムで全店舗を見る'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applySelectStores(List<String> storeIds) async {
    try {
      final updated = await _communityService.selectStores(storeIds);
      if (!mounted) return;
      setState(() => _settings = updated);
      _fetchStores(); // ロック状態を更新
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('店舗の選択に失敗しました: $e')));
    }
  }

  void _showUpgradeDialog(CamillColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'プレミアムプラン',
          style: camillBodyStyle(
            18,
            colors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          '有料プランにアップグレードすると、地域内の全店舗のクーポン情報と遠隔地5箇所の閲覧が可能になります。',
          style: camillBodyStyle(14, colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '閉じる',
              style: camillBodyStyle(
                14,
                colors.textMuted,
                weight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/plan');
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(themeProvider, (_, next) {
      _mapStyleNotifier.value = communityMapStyle(next.isDarkNow);
    });
    final colors = context.colors;
    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Google Maps（全画面）
          Positioned.fill(
            child: ValueListenableBuilder<String>(
              valueListenable: _mapStyleNotifier,
              builder: (_, style, _) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentCenter,
                  zoom: _currentZoom,
                ),
                style: style,
                markers: _markers,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // _initLocation() がマップ生成前に完了していた場合に備えてカメラを移動
                  if (_currentCenter != _defaultLatLng) {
                    controller.moveCamera(
                      CameraUpdate.newLatLng(_currentCenter),
                    );
                  }
                },
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                onTap: (_) {
                  setState(() => _highlightedStoreId = null);
                },
              ),
            ),
          ),

          // ヘッダー（タイトル + 位置情報バナー）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, statusBarH + 10, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.background.withAlpha(0)],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'コミュニティ',
                        style: camillBodyStyle(
                          26,
                          colors.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await context.push('/community-settings');
                          if (mounted) _loadSettings();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surfaceBorder),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_locationPermissionGranted) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _initLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 14,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '位置情報を許可するとより正確な情報が見られます',
                              style: camillBodyStyle(11, colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 現在地ボタン
          if (_locationPermissionGranted)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * _sheetSize + 16,
              child: GestureDetector(
                onTap: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.medium,
                        timeLimit: Duration(seconds: 5),
                      ),
                    );
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(pos.latitude, pos.longitude),
                      ),
                    );
                  } catch (_) {}
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),

          // ズームレベル不足メッセージ
          if (_currentZoom < _minFetchZoom)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height * _sheetSize + 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'ズームインすると店舗が表示されます',
                    style: camillBodyStyle(12, colors.textSecondary),
                  ),
                ),
              ),
            ),

          // ボトムシート
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.38,
            minChildSize: 0.1,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.1, 0.38, 0.93],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // ドラッグハンドル + ヘッダー
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _cycleSheetSize,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colors.textMuted.withAlpha(100),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 検索ボタン・パネル・ヘッダー（しまった時は一括で縮んで隠れる）
                          AnimatedSize(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.hardEdge,
                            child: _isSheetCollapsed
                                ? const SizedBox(width: double.infinity)
                                : Column(
                                    children: [
                                      _buildSearchButton(colors),
                                      // 検索パネル（ぬるっとスライドイン）
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topCenter,
                                        clipBehavior: Clip.hardEdge,
                                        child: _searchPanelOpen
                                            ? TweenAnimationBuilder<double>(
                                                key: const ValueKey(
                                                  'search_panel',
                                                ),
                                                tween: Tween(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                duration: const Duration(
                                                  milliseconds: 340,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                builder:
                                                    (context, value, child) {
                                                      return Transform.translate(
                                                        offset: Offset(
                                                          0,
                                                          -8 * (1 - value),
                                                        ),
                                                        child: Opacity(
                                                          opacity: value,
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                child: _buildSearchPanel(
                                                  colors,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      // 近くの店舗ヘッダー
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          2,
                                          20,
                                          8,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '近くの店舗',
                                              style: camillBodyStyle(
                                                15,
                                                colors.textPrimary,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (!_loading)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colors.primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${_filteredStores.length}件',
                                                  style: camillBodyStyle(
                                                    12,
                                                    colors.primary,
                                                    weight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => _fetchStores(),
                                              child: Icon(
                                                Icons.refresh,
                                                size: 20,
                                                color: colors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // 店舗リスト or ローディング or 空状態
                    _buildStoreSliver(colors),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const _yenSteps = [
    10,
    50,
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
  ];

  double _yenIndex(int yen) {
    final i = _yenSteps.indexOf(yen);
    return (i >= 0 ? i : 0).toDouble();
  }

  bool get _hasActiveFilter => _filterFree || _minDiscountAmount != null;

  bool get _isSheetCollapsed => _sheetSize < 0.18;

  Widget _buildSearchButton(CamillColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _searchPanelOpen = !_searchPanelOpen;
            if (_searchPanelOpen) {
              _sliderValue = _yenIndex(_minDiscountAmount ?? 10).toDouble();
            }
          });
          if (_searchPanelOpen) {
            _sheetController.animateTo(
              0.55,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          } else if (_sheetController.size > 0.55) {
            _sheetController.animateTo(
              0.38,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hasActiveFilter
                ? colors.primary.withAlpha(15)
                : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasActiveFilter ? colors.primary : colors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 18,
                color: _hasActiveFilter ? colors.primary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasActiveFilter
                      ? _filterFree
                            ? '無料券で絞り込み中'
                            : '$_minDiscountAmount円以上で絞り込み中'
                      : 'クーポンを検索',
                  style: camillBodyStyle(
                    13,
                    _hasActiveFilter ? colors.primary : colors.textMuted,
                    weight: _hasActiveFilter
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (_hasActiveFilter)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _filterFree = false;
                      _minDiscountAmount = null;
                      _searchPanelOpen = false;
                    });
                    _sheetController.animateTo(
                      0.38,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Icon(Icons.close, size: 18, color: colors.textMuted),
                )
              else
                Icon(
                  _searchPanelOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel(CamillColors colors) {
    final sliderDisabled = _filterFree;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          // ── 無料券ボタン ──
          GestureDetector(
            onTap: () {
              setState(() {
                _filterFree = !_filterFree;
                if (_filterFree) _minDiscountAmount = null;
                _searchPanelOpen = false;
              });
              _sheetController.animateTo(
                0.38,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _filterFree ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filterFree ? colors.primary : colors.surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 18,
                    color: _filterFree ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '無料券',
                    style: camillBodyStyle(
                      13,
                      _filterFree ? Colors.white : colors.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_filterFree)
                    Icon(Icons.check, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── 割引額スライダー（円のみ）──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '割引額',
                      style: camillBodyStyle(
                        12,
                        sliderDisabled
                            ? colors.textMuted
                            : colors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sliderDisabled
                            ? colors.surfaceBorder.withAlpha(80)
                            : colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_yenSteps[_sliderValue.round()]}円以上',
                        style: camillBodyStyle(
                          15,
                          sliderDisabled ? colors.textMuted : colors.primary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: sliderDisabled
                        ? colors.textMuted.withAlpha(60)
                        : colors.primary,
                    inactiveTrackColor: colors.surfaceBorder,
                    thumbColor: sliderDisabled
                        ? colors.textMuted.withAlpha(80)
                        : colors.primary,
                    overlayColor: colors.primary.withAlpha(30),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: sliderDisabled
                        ? null
                        : (v) => setState(() => _sliderValue = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10円', style: camillBodyStyle(10, colors.textMuted)),
                      Text(
                        '500円',
                        style: camillBodyStyle(10, colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: sliderDisabled
                      ? null
                      : () {
                          setState(() {
                            _minDiscountAmount =
                                _yenSteps[_sliderValue.round()];
                            _filterFree = false;
                            _searchPanelOpen = false;
                          });
                          _sheetController.animateTo(
                            0.38,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sliderDisabled
                          ? colors.textMuted.withAlpha(40)
                          : colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'この金額で検索',
                        style: camillBodyStyle(
                          14,
                          sliderDisabled ? colors.textMuted : Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSliver(CamillColors colors) {
    if (_isSheetCollapsed) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (_loading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(_error!, style: camillBodyStyle(13, colors.textMuted)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _fetchStores,
                child: Text(
                  '再試行',
                  style: camillBodyStyle(
                    13,
                    colors.primary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_stores.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_outlined, color: colors.textMuted, size: 40),
              const SizedBox(height: 8),
              Text(
                'このエリアにクーポンはまだありません',
                style: camillBodyStyle(13, colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredStores;

    if (filtered.isEmpty && (_filterFree || _minDiscountAmount != null)) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, color: colors.textMuted, size: 36),
              const SizedBox(height: 8),
              Text(
                '条件に合うクーポンが見つかりません',
                style: camillBodyStyle(13, colors.textMuted),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _filterFree = false;
                  _minDiscountAmount = null;
                }),
                child: Text(
                  'フィルターを解除',
                  style: camillBodyStyle(
                    13,
                    colors.primary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final store = filtered[index];
        return StoreCard(
          store: store,
          isHighlighted: store.storeId == _highlightedStoreId,
          onTap: () => _onCardTap(store),
          onLockTap: () => _onLockedStoreTap(store),
        );
      }, childCount: filtered.length),
    );
  }
}
