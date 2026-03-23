import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/camill_theme.dart';
import 'core/theme/camill_theme_mode.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/phone_verify_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/receipt/screens/camera_screen.dart';
import 'features/receipt/screens/analysis_preview_screen.dart';
import 'features/receipt/screens/manual_input_screen.dart';
import 'features/coupon/screens/coupon_wallet_screen.dart';
import 'features/bill/screens/bill_screen.dart';
import 'features/receipt/screens/receipt_list_screen.dart';
import 'features/receipt/screens/receipt_edit_screen.dart';
import 'features/profile/screens/notification_settings_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/reports/screens/report_screen.dart';
import 'features/subscriptions/screens/subscription_screen.dart';
import 'features/data/screens/data_screen.dart';
import 'firebase_options.dart';
import 'shared/models/receipt_model.dart';
import 'shared/models/summary_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // テーマを起動前に読み込んでフラッシュを防ぐ
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('camill_theme');
  CamillThemeMode initialTheme = CamillThemeMode.midnight;
  if (saved != null) {
    try {
      final mode = CamillThemeMode.values.byName(saved);
      if (!mode.hasCat) initialTheme = mode;
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith(
          (ref) => ThemeNotifier.withInitial(initialTheme),
        ),
      ],
      child: const SmartReceiptApp(),
    ),
  );
}

final _router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/phone-verify';
    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && state.matchedLocation == '/login') return '/';
    return null;
  },
  refreshListenable: _AuthChangeNotifier(),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainShell()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/phone-verify',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PhoneVerifyScreen(
          email: extra['email'] as String,
          displayName: extra['displayName'] as String,
        );
      },
    ),
    GoRoute(path: '/camera', builder: (context, state) => const CameraScreen()),
    GoRoute(
      path: '/manual-input',
      builder: (context, state) => const ManualInputScreen(),
    ),
    GoRoute(
      path: '/receipt-preview',
      builder: (_, state) {
        final analysis = state.extra as ReceiptAnalysis;
        return AnalysisPreviewScreen(analysis: analysis);
      },
    ),
    GoRoute(
      path: '/coupon-wallet',
      builder: (context, state) => const CouponWalletScreen(),
    ),
    GoRoute(path: '/bills', builder: (context, state) => const BillScreen()),
    GoRoute(
      path: '/receipts',
      builder: (context, state) => const ReceiptListScreen(),
    ),
    GoRoute(
      path: '/receipt-edit',
      builder: (_, state) {
        final receipt = state.extra as ReceiptListItem;
        return ReceiptEditScreen(receipt: receipt);
      },
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/report',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ReportScreen(
          year: extra['year'] as int,
          month: extra['month'] as int,
        );
      },
    ),
    GoRoute(
      path: '/subscriptions',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/chart',
      builder: (context, state) => const BalanceChartScreen(),
    ),
  ],
);

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

class SmartReceiptApp extends ConsumerWidget {
  const SmartReceiptApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'camill',
      theme: CamillThemeData.build(themeMode),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
