import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/camill_colors.dart';
import '../home/screens/home_screen.dart';
import '../data/screens/data_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _speedDialOpen = false;
  final _calendarReturnNotifier = ValueNotifier<int>(0);
  late AnimationController _animController;
  late CurvedAnimation _slideAnim;
  late CurvedAnimation _fadeAnim;
  late Animation<double> _fabRotation;
  late Animation<double> _fabScale;
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
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    // 前半50%でシュッと回転を終わらせる
    _fabRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
      ),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _slideAnim.dispose();
    _animController.dispose();
    _pageController.dispose();
    _calendarReturnNotifier.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() => _speedDialOpen = !_speedDialOpen);
    if (_speedDialOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _closeSpeedDial() {
    if (_speedDialOpen) {
      setState(() => _speedDialOpen = false);
      _animController.reverse();
    }
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
            top: 0, left: 0, right: 0,
            bottom: navBarHeight,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HomeScreen(),
                DataScreen(),
                CalendarScreen(returnToTodayNotifier: _calendarReturnNotifier),
                ProfileScreen(),
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
                    colors: [
                      colors.background.withAlpha(0),
                      colors.background,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          // ナビバー（Stackの中に配置 → ブラーが届く）
          Positioned(
            bottom: 0, left: 0, right: 0,
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
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: colors.isDark
                          ? Colors.black.withAlpha(40)
                          : Colors.white.withAlpha(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // スピードダイアル（ブラーの上）
          if (_speedDialOpen) _buildSpeedDial(colors),
          // FAB（常にブラーの上）
          Positioned(
            bottom: navBarHeight - 30,
            left: 0,
            right: 0,
            child: Center(child: _buildCenterFab(colors)),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFab(CamillColors colors) {
    return GestureDetector(
      onTap: () => _onNavTap(2),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _speedDialOpen ? colors.danger : colors.fabBackground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.fabBackground.withAlpha(80),
              blurRadius: 12,
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
    );
  }

  Widget _buildSpeedDial(CamillColors colors) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 56.0 + bottomInset;
    return Positioned(
      bottom: navBarHeight + 42, // FABトップ(+30) + 12px gap
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _SpeedDialItem(
                icon: Icons.camera_alt,
                label: '撮影',
                colors: colors,
                onTap: () {
                  _closeSpeedDial();
                  context.push('/camera');
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _SpeedDialItem(
                icon: Icons.edit_note,
                label: '手動入力',
                colors: colors,
                onTap: () {
                  _closeSpeedDial();
                  context.push('/manual-input');
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.7),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _SpeedDialItem(
                icon: Icons.receipt_long,
                label: '請求書',
                colors: colors,
                onTap: () {
                  _closeSpeedDial();
                  context.push('/bills');
                },
              ),
            ),
          ),
        ],
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

class _SpeedDialItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final CamillColors colors;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: colors.primary, size: 26),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
