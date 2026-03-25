import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        context.push('/phone-verify', extra: {
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
        });
      }
    } catch (e) {
      // silently swallow
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CamillThemeData.build(CamillColors.naturalLight),
      child: Builder(builder: (ctx) {
        final colors = ctx.colors;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            title: Text('新規登録', style: camillHeadingStyle(17, colors.textPrimary)),
            iconTheme: IconThemeData(color: colors.textSecondary),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'アカウント作成',
                      style: camillHeadingStyle(22, colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'メールアドレスと電話番号の両方で本人確認を行います',
                      style: camillBodyStyle(13, colors.textMuted),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '表示名',
                        prefixIcon: Icon(Icons.person_outlined, color: colors.textMuted),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? '表示名を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'パスワード（6文字以上）',
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.fabIcon,
                      ),
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.fabIcon),
                            )
                          : Text('次へ（電話番号認証）',
                              style: camillBodyStyle(16, colors.fabIcon)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('ログインに戻る',
                          style: camillBodyStyle(14, colors.primary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
