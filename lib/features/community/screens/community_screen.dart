import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/camill_theme_mode.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/community_model.dart';
import '../../../shared/services/api_service.dart';
import '../services/community_service.dart';
import '../widgets/map_styles.dart';
import '../widgets/store_card.dart';

/// 最小ズームレベル（これ以上ズームアウトするとフェッチしない）
const _minFetchZoom = 13.0;

/// デフォルト位置（東京駅）
const _defaultLatLng = LatLng(35.6812, 139.7671);

class CommunityScreen extends ConsumerStatefulWidget {
  final String? focusStoreId;
  final bool blurred;

  const CommunityScreen({super.key, this.focusStoreId, this.blurred = false});

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
  double _sheetSize = 0.32;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
    _initLocation();
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
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
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
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentCenter),
      );
      _fetchStores();
    } catch (_) {
      _fetchStores();
    }
  }

  Future<void> _fetchStores() async {
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
    final themeMode = ref.read(themeProvider);

    _markers = _stores.map((store) {
      return Marker(
        markerId: MarkerId(store.storeId),
        position: LatLng(store.latitude, store.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          store.isFeatured
              ? BitmapDescriptor.hueOrange
              : _hueForTheme(themeMode),
        ),
        onTap: () => _onPinTap(store),
      );
    }).toSet();
  }

  double _hueForTheme(CamillThemeMode mode) {
    switch (mode) {
      case CamillThemeMode.midnight:
        return BitmapDescriptor.hueGreen;
      case CamillThemeMode.natural:
        return BitmapDescriptor.hueGreen;
      case CamillThemeMode.classic:
        return BitmapDescriptor.hueAzure;
    }
  }

  void _onPinTap(CommunityStore store) {
    setState(() => _highlightedStoreId = store.storeId);
    // ボトムシートを展開
    _sheetController.animateTo(
      0.45,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    // リストを該当店舗までスクロール
    final index = _stores.indexWhere((s) => s.storeId == store.storeId);
    if (index >= 0 && _listScrollController.hasClients) {
      _listScrollController.animateTo(
        index * 72.0, // カードの推定高さ
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onCardTap(CommunityStore store) {
    setState(() => _highlightedStoreId = store.storeId);
    // 地図を店舗の位置にフォーカス
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(store.latitude, store.longitude),
        16.0,
      ),
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
    double next;
    if (current < 0.2) {
      next = 0.32; // しまう → マニュアル
    } else if (current < 0.6) {
      next = 0.93; // マニュアル → フル画面
    } else {
      next = 0.08; // フル画面 → しまう
    }
    _sheetController.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_currentZoom >= _minFetchZoom) {
        _fetchStores();
      }
    });
  }

  void _showUpgradeDialog(CamillColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'プレミアムプラン',
          style: camillBodyStyle(18, colors.textPrimary, weight: FontWeight.w700),
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
              style: camillBodyStyle(14, colors.textMuted, weight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscriptions');
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final colors = context.colors;
    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Google Maps（全画面）
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCenter,
                zoom: _currentZoom,
              ),
              style: communityMapStyle(themeMode),
              markers: _markers,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              onTap: (_) {
                setState(() => _highlightedStoreId = null);
              },
            ),
          ),

          // ヘッダー（タイトル + 位置情報バナー）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ImageFiltered(
              imageFilter: widget.blurred
                  ? ImageFilter.blur(sigmaX: 6, sigmaY: 6)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, statusBarH + 10, 20, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.background,
                      colors.background.withAlpha(0),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'コミュニティ',
                      style: camillBodyStyle(
                        26,
                        colors.textPrimary,
                        weight: FontWeight.w800,
                      ),
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
                              style: camillBodyStyle(
                                11,
                                colors.textSecondary,
                              ),
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
            initialChildSize: 0.32,
            minChildSize: 0.08,
            maxChildSize: 0.93,
            snap: true,
            snapSizes: const [0.08, 0.32, 0.93],
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_stores.length}件',
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

  Widget _buildStoreSliver(CamillColors colors) {
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
                  style: camillBodyStyle(13, colors.primary,
                      weight: FontWeight.w600),
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final store = _stores[index];
          return StoreCard(
            store: store,
            isHighlighted: store.storeId == _highlightedStoreId,
            onTap: () => _onCardTap(store),
            onLockTap: () => _showUpgradeDialog(colors),
          );
        },
        childCount: _stores.length,
      ),
    );
  }
}
