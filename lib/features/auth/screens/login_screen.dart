import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _loadingGoogle = false;
  bool _loadingApple = false;
  bool _obscurePassword = true;

  late final AnimationController _heroCtrl;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoFade = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _taglineFade = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0.35, 0.9, curve: Curves.easeOut),
    );

    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await _authService.signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted && e.toString() != 'Exception: cancelled') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Googleサインインに失敗しました')));
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _loginWithApple() async {
    setState(() => _loadingApple = true);
    try {
      await _authService.signInWithApple();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted && e.toString() != 'Exception: cancelled') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appleサインインに失敗しました')));
      }
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = CamillColors.naturalLight;
    const gradientStart = Color(0xFF6AA864);
    const gradientEnd = Color(0xFF4A8545);

    return Theme(
      data: CamillThemeData.build(colors),
      child: Scaffold(
        backgroundColor: colors.surface,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ヒーロー ───────────────────────────────────────────
              ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientStart, gradientEnd],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: Text(
                              'camill',
                              style: GoogleFonts.outfit(
                                fontSize: 66,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _taglineFade,
                          child: Text(
                            '家計を、もっとシンプルに',
                            style: GoogleFonts.zenMaruGothic(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                        const SizedBox(height: 52),
                      ],
                    ),
                  ),
                ),
              ),

              // ── フォーム ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocus),
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: colors.textMuted,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'メールアドレスを入力してください'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: colors.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? '6文字以上で入力してください'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.fabIcon,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.fabIcon,
                                  ),
                                )
                              : Text(
                                  'ログイン',
                                  style: camillBodyStyle(
                                    16,
                                    colors.fabIcon,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: colors.surfaceBorder),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'または',
                                style: camillBodyStyle(13, colors.textMuted),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: colors.surfaceBorder),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(
                              color: colors.primary.withValues(alpha: 0.55),
                            ),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => context.push('/register'),
                          child: Text(
                            '新規登録',
                            style: camillBodyStyle(
                              16,
                              colors.primary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: colors.surfaceBorder),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'ソーシャルログイン',
                                style: camillBodyStyle(12, colors.textMuted),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: colors.surfaceBorder),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SocialButton(
                          onPressed:
                              (_loadingGoogle || _loadingApple || _loading)
                              ? null
                              : _loginWithGoogle,
                          loading: _loadingGoogle,
                          icon: _GoogleLogo(),
                          label: 'Googleでサインイン',
                          borderColor: colors.surfaceBorder,
                          textColor: colors.textPrimary,
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 12),
                          _SocialButton(
                            onPressed:
                                (_loadingGoogle || _loadingApple || _loading)
                                ? null
                                : _loginWithApple,
                            loading: _loadingApple,
                            icon: const Icon(
                              Icons.apple,
                              size: 22,
                              color: Colors.black,
                            ),
                            label: 'Appleでサインイン',
                            borderColor: Colors.black,
                            textColor: Colors.black,
                            fillColor: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.loading,
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.textColor,
    this.fillColor,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final Widget icon;
  final String label;
  final Color borderColor;
  final Color textColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: fillColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: loading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: camillBodyStyle(
                    15,
                    textColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Red arc (top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57,
      1.57,
      true,
      paint,
    );

    // Blue arc (bottom-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.0,
      1.57,
      true,
      paint,
    );

    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.57,
      1.57,
      true,
      paint,
    );

    // Green arc (top-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14,
      1.57,
      true,
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // Blue right bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.22, r * 0.95, r * 0.44),
      paint,
    );

    // Re-draw white inner circle to clip
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);

    // Inner blue circle (right portion)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.58),
      -0.52,
      1.04,
      true,
      paint,
    );

    // White core
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.36, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter _) => false;
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 52);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 26,
      size.width,
      size.height - 52,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper _) => false;
}
