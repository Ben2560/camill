import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/camill_colors.dart';
import '../../core/theme/camill_theme.dart';
import '../../shared/services/api_service.dart';
import '../../shared/widgets/month_greeting_overlay.dart';
import '../home/screens/home_screen.dart';
import '../community/screens/community_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _speedDialOpen = false;
  bool _speedDialVisible = false;
  bool _fabPressed = false;
  bool _fabLongPressActivated = false;
  Timer? _fabLongPressTimer;
  int? _analysisCount;
  int? _analysisLimit;
  bool _isPremium = false;
  final _apiService = ApiService();
  final _calendarReturnNotifier = ValueNotifier<int>(0);
  final _calendarRefreshNotifier = ValueNotifier<int>(0);
  final _profileRefreshNotifier = ValueNotifier<int>(0);
  bool _showMonthGreeting = false;
  int _greetingMonth = 1;
  late AnimationController _animController;
  late CurvedAnimation _slideAnim;
  late CurvedAnimation _fadeAnim;
  late Animation<double> _fabScale;
  late AnimationController _fabSpinController;
  late Animation<double> _fabRotation;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _fabSpinController = AnimationController(
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 480),
      vsync: this,
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 1.125).animate(
      CurvedAnimation(
        parent: _fabSpinController,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      ),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _pageController = PageController();
    _checkMonthGreeting();
  }

  Future<void> _checkMonthGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month}';
    final lastSeen = prefs.getString('last_month_greeting');
    if (lastSeen != currentKey) {
      await prefs.setString('last_month_greeting', currentKey);
      if (mounted) {
        setState(() {
          _showMonthGreeting = true;
          _greetingMonth = now.month;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _slideAnim.dispose();
    _animController.dispose();
    _fabSpinController.dispose();
    _pageController.dispose();
    _fabLongPressTimer?.cancel();
    _calendarReturnNotifier.dispose();
    _calendarRefreshNotifier.dispose();
    _profileRefreshNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchBillingStatus() async {
    try {
      final data = await _apiService.get('/billing/status');
      if (!mounted) return;
      setState(() {
        _analysisCount =
            (data['analysis_count_this_month'] as num?)?.toInt() ?? 0;
        _analysisLimit = (data['analysis_limit'] as num?)?.toInt() ?? 10;
        _isPremium = data['is_premium'] as bool? ?? false;
      });
    } catch (_) {}
  }

  void _toggleSpeedDial() {
    if (_speedDialOpen) {
      setState(() => _speedDialOpen = false);
      _fabSpinController.reverse();
      _animController.reverse().then((_) {
        if (mounted) setState(() => _speedDialVisible = false);
      });
    } else {
      setState(() {
        _speedDialOpen = true;
        _speedDialVisible = true;
      });
      _fabSpinController.forward();
      _animController.forward();
      _fetchBillingStatus();
    }
  }

  void _closeSpeedDial() {
    if (_speedDialOpen) {
      setState(() => _speedDialOpen = false);
      _fabSpinController.reverse();
      _animController.reverse().then((_) {
        if (mounted) setState(() => _speedDialVisible = false);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    _closeSpeedDial();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1000,
    );
    if (picked == null || !mounted) return;
    context.push('/camera', extra: File(picked.path));
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _toggleSpeedDial();
      return;
    }
    _closeSpeedDial();
    if (index == 3 && _currentIndex == 3) {
      _calendarReturnNotifier.value++;
      return;
    }
    if (index == 3 && _currentIndex != 3) {
      _calendarRefreshNotifier.value++;
    }
    if (index == 4) {
      _profileRefreshNotifier.value++;
    }
    final pageIndex = index > 2 ? index - 1 : index;
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 56.0 + bottomInset;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // コンテンツ（ナビバー分の余白を下に確保）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: navBarHeight,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HomeScreen(),
                CommunityScreen(blurred: _speedDialOpen),
                CalendarScreen(
                  returnToTodayNotifier: _calendarReturnNotifier,
                  refreshNotifier: _calendarRefreshNotifier,
                ),
                ProfileScreen(refreshNotifier: _profileRefreshNotifier),
              ],
            ),
          ),
          // グラデーションフェード（コンテンツとナビバーの境目）
          Positioned(
            bottom: navBarHeight,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.background.withAlpha(0), colors.background],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          // ナビバー（Stackの中に配置 → ブラーが届く）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(colors),
          ),
          // ブラーオーバーレイ（ナビバーも含めて全体にかかる）
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: IgnorePointer(
                ignoring: !_speedDialOpen,
                child: GestureDetector(
                  onTap: _closeSpeedDial,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: colors.isDark
                          ? Colors.black.withAlpha(70)
                          : Colors.black.withAlpha(40),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // スピードダイアル（ブラーの上）
          if (_speedDialVisible) _buildSpeedDial(colors),
          // FAB（常にブラーの上）
          Positioned(
            bottom: navBarHeight - 30,
            left: 0,
            right: 0,
            child: Center(child: _buildCenterFab(colors)),
          ),
          // 月初グリーティング（最前面）
          if (_showMonthGreeting)
            Positioned.fill(
              child: MonthGreetingOverlay(
                month: _greetingMonth,
                onDismiss: () => setState(() => _showMonthGreeting = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterFab(CamillColors colors) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _fabPressed = true);
        _fabLongPressActivated = false;
        _fabLongPressTimer?.cancel();
        _fabLongPressTimer = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _fabLongPressActivated = true;
          _fabPressed = false;
          HapticFeedback.mediumImpact();
          context.push('/camera', extra: 'camera');
        });
      },
      onTapUp: (_) {
        _fabLongPressTimer?.cancel();
        setState(() => _fabPressed = false);
      },
      onTapCancel: () {
        _fabLongPressTimer?.cancel();
        setState(() => _fabPressed = false);
      },
      onTap: () {
        if (_fabLongPressActivated) {
          _fabLongPressActivated = false;
          return;
        }
        _onNavTap(2);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _fabPressed ? 1.18 : 1.0,
        duration: _fabPressed
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 200),
        curve: _fabPressed ? Curves.easeOut : Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _speedDialOpen ? colors.danger : colors.fabBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.fabBackground.withAlpha(_fabPressed ? 120 : 80),
                blurRadius: _fabPressed ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _fabScale,
            child: RotationTransition(
              turns: _fabRotation,
              child: Icon(Icons.add, color: colors.fabIcon, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial(CamillColors colors) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topInset + 36,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(_slideAnim),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpeedDialHeader(colors: colors),
              const SizedBox(height: 12),
              _ScanInfoCard(
                colors: colors,
                analysisCount: _analysisCount,
                analysisLimit: _analysisLimit,
                isPremium: _isPremium,
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.camera_alt_rounded,
                label: 'カメラで撮影',
                sublabel: 'レシートや請求書をその場で撮る',
                colors: colors,
                onTap: () {
                  _closeSpeedDial();
                  context.push('/camera', extra: 'camera');
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.photo_library_rounded,
                label: 'ギャラリーから選択',
                sublabel: '保存済みの写真を使う',
                colors: colors,
                onTap: _pickFromGallery,
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.edit_note_rounded,
                label: '手動入力',
                sublabel: '金額・品目を直接入力',
                colors: colors,
                onTap: () {
                  _closeSpeedDial();
                  context.push('/manual-input');
                },
              ),
              const SizedBox(height: 10),
              _SpeedDialTips(colors: colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(CamillColors colors) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Material(
          color: colors.navBackground,
          child: SizedBox(
            height: 56 + bottomInset,
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      _BottomNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'ホーム',
                        selected: _currentIndex == 0,
                        colors: colors,
                        onTap: () => _onNavTap(0),
                      ),
                      _BottomNavItem(
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore,
                        label: 'コミュニティ',
                        selected: _currentIndex == 1,
                        colors: colors,
                        onTap: () => _onNavTap(1),
                      ),
                      const Expanded(child: SizedBox()),
                      _BottomNavItem(
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month,
                        label: 'カレンダー',
                        selected: _currentIndex == 3,
                        colors: colors,
                        onTap: () => _onNavTap(3),
                      ),
                      _BottomNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'プロフィール',
                        selected: _currentIndex == 4,
                        colors: colors,
                        onTap: () => _onNavTap(4),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final CamillColors colors;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.navActive : colors.navInactive;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.circle,
        radius: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SpeedDialHeader extends StatelessWidget {
  final CamillColors colors;
  const _SpeedDialHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '情報を登録する',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 5.5),
            child: Text(
              'レシート・請求書・手入力に対応',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanInfoCard extends StatelessWidget {
  final CamillColors colors;
  final int? analysisCount;
  final int? analysisLimit;
  final bool isPremium;
  const _ScanInfoCard({
    required this.colors,
    this.analysisCount,
    this.analysisLimit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      (icon: Icons.receipt_long_outlined, label: 'レシート'),
      (icon: Icons.medical_information_outlined, label: '医療明細'),
      (icon: Icons.description_outlined, label: '請求書'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '撮影できるもの',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
              _UsageBadge(
                colors: colors,
                analysisCount: analysisCount,
                analysisLimit: analysisLimit,
                isPremium: isPremium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: types
                .map(
                  (t) => Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(t.icon, color: colors.primary, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final CamillColors colors;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sublabel,
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsageBadge extends StatelessWidget {
  final CamillColors colors;
  final int? analysisCount;
  final int? analysisLimit;
  final bool isPremium;

  const _UsageBadge({
    required this.colors,
    this.analysisCount,
    this.analysisLimit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    if (analysisCount == null || analysisLimit == null) {
      return const SizedBox.shrink();
    }
    final remaining = (analysisLimit! - analysisCount!).clamp(
      0,
      analysisLimit!,
    );
    final isEmpty = remaining == 0;
    final badgeColor = isEmpty
        ? colors.danger
        : remaining <= 1
        ? Colors.orange
        : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty ? Icons.block_rounded : Icons.camera_alt_outlined,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            isEmpty ? '今月の上限に達しました' : '今月あと$remaining枚 登録可能',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedDialTips extends StatelessWidget {
  final CamillColors colors;
  const _SpeedDialTips({required this.colors});

  @override
  Widget build(BuildContext context) {
    final tips = [
      (icon: Icons.wb_sunny_outlined, text: '明るい場所で'),
      (icon: Icons.straighten, text: '全体が写るように'),
      (icon: Icons.blur_off, text: 'ブレないように'),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Color.alphaBlend(colors.primary.withAlpha(12), colors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color.alphaBlend(
              colors.primary.withAlpha(40),
              colors.surfaceBorder,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '撮影のコツ',
              style: camillBodyStyle(
                12,
                colors.primary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tips
                  .map(
                    (t) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 14, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          t.text,
                          style: camillBodyStyle(11, colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
