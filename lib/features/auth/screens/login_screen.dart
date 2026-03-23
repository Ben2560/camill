import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/camill_theme_mode.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
    return Theme(
      data: CamillThemeData.build(CamillThemeMode.natural),
      child: Builder(builder: (ctx) {
        final colors = ctx.colors;
        return Scaffold(
          backgroundColor: colors.background,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(Icons.receipt_long, size: 64, color: colors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'SmartReceipt',
                      textAlign: TextAlign.center,
                      style: camillHeadingStyle(28, colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '賢く管理、賢く節約',
                      textAlign: TextAlign.center,
                      style: camillBodyStyle(14, colors.textMuted),
                    ),
                    const Spacer(),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      decoration: InputDecoration(
                        labelText: 'メールアドレス',
                        prefixIcon: Icon(Icons.email_outlined, color: colors.textMuted),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'メールアドレスを入力してください' : null,
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
                        prefixIcon: Icon(Icons.lock_outlined, color: colors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? '6文字以上で入力してください' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.fabIcon,
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.fabIcon),
                            )
                          : Text('ログイン', style: camillBodyStyle(16, colors.fabIcon)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                      ),
                      onPressed: () => context.push('/register'),
                      child: Text('新規登録', style: camillBodyStyle(16, colors.primary)),
                    ),
                    const Spacer(),
                  ],
                ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
