import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../core/theme/camill_theme_mode.dart';
import '../services/auth_service.dart';

class PhoneVerifyScreen extends StatefulWidget {
  final String email;
  final String displayName;

  const PhoneVerifyScreen({
    super.key,
    required this.email,
    required this.displayName,
  });

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onAutoVerified: (credential) async {
          await _authService.linkPhoneCredential(
              credential.verificationId ?? '', credential.smsCode ?? '');
          await _completeRegistration(phone);
        },
        onFailed: (e) {},
        onCodeSent: (verificationId, _) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _loading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() => _loading = true);
    try {
      await _authService.linkPhoneCredential(
          _verificationId!, _codeController.text.trim());
      await _completeRegistration(_phoneController.text.trim());
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeRegistration(String phone) async {
    try {
      await _authService.registerUserInBackend(
        displayName: widget.displayName,
        email: widget.email,
        phone: phone,
      );
    } catch (_) {
      // バックエンド登録失敗は無視してホームに進む
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CamillThemeData.build(CamillThemeMode.natural),
      child: Builder(builder: (ctx) {
        final colors = ctx.colors;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            title: Text('電話番号認証', style: camillHeadingStyle(17, colors.textPrimary)),
            iconTheme: IconThemeData(color: colors.textSecondary),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.phone_android, size: 48, color: colors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _codeSent ? 'SMSで届いた認証コードを入力してください' : '電話番号を入力してください',
                    textAlign: TextAlign.center,
                    style: camillBodyStyle(16, colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '不正利用防止のため電話番号認証が必要です',
                    textAlign: TextAlign.center,
                    style: camillBodyStyle(13, colors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  if (!_codeSent) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '電話番号（例: +819012345678）',
                        prefixIcon: Icon(Icons.phone_outlined, color: colors.textMuted),
                        hintText: '+81 から始まる国際形式',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.fabIcon,
                      ),
                      onPressed: _loading ? null : _sendCode,
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.fabIcon))
                          : Text('SMSを送信', style: camillBodyStyle(16, colors.fabIcon)),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '認証コード（6桁）',
                        prefixIcon: Icon(Icons.sms_outlined, color: colors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.fabIcon,
                      ),
                      onPressed: _loading ? null : _verifyCode,
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.fabIcon))
                          : Text('認証して登録を完了',
                              style: camillBodyStyle(16, colors.fabIcon)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _codeSent = false),
                      child: Text('電話番号を変更する',
                          style: camillBodyStyle(14, colors.primary)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
