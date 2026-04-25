import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/user_prefs.dart';
import '../../../core/theme/camill_colors.dart';
import '../../../core/theme/camill_theme.dart';
import '../../../shared/widgets/camill_card.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../auth/services/auth_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _avatarPathKey = 'profile_avatar_path';

  final _authService = AuthService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _realNameCtrl;
  late final TextEditingController _phoneCtrl;

  String? _avatarPath;
  bool _saving = false;
  bool _loadingProfile = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: _user?.email ?? '');
    _realNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadAvatar();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _realNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// UID 別のアバターファイル名を返す
  static String _avatarFileName() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    return 'profile_avatar_$uid.jpg';
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = await UserPrefs.getString(prefs, _avatarPathKey);
    final dir = await getApplicationDocumentsDirectory();
    final expectedName = _avatarFileName();
    final expectedPath = '${dir.path}/$expectedName';

    if (stored != null) {
      final rawName = stored.contains('/') ? stored.split('/').last : stored;
      // 旧ファイル名（profile_avatar.jpg 等）→ UID 別ファイルへ移行
      if (rawName != expectedName) {
        final oldPath = '${dir.path}/$rawName';
        if (File(oldPath).existsSync() && !File(expectedPath).existsSync()) {
          await File(oldPath).copy(expectedPath);
        }
      }
    }

    if (File(expectedPath).existsSync()) {
      if (mounted) setState(() => _avatarPath = expectedPath);
      return;
    }

    // ローカルにない場合はサーバーから復元
    try {
      final profile = await _authService.fetchProfile();
      final avatarData = profile['avatar_data'] as String?;
      if (avatarData != null && avatarData.contains(',')) {
        final b64 = avatarData.split(',').last;
        final bytes = base64Decode(b64);
        await File(expectedPath).writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await UserPrefs.setString(prefs, _avatarPathKey, expectedName);
        if (mounted) setState(() => _avatarPath = expectedPath);
      }
    } catch (e) {
      debugPrint('avatar restore failed: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _authService.fetchProfile();
      if (!mounted) return;
      _realNameCtrl.text = data['real_name'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
    } catch (e) {
      debugPrint('fetchProfile failed: $e');
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked == null || !mounted) return;

    final tempFile = File(picked.path);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = _avatarFileName();
    final dest = '${dir.path}/$fileName';
    await tempFile.copy(dest);
    if (tempFile.existsSync()) tempFile.deleteSync();

    final prefs = await SharedPreferences.getInstance();
    await UserPrefs.setString(prefs, _avatarPathKey, fileName);
    if (mounted) setState(() => _avatarPath = dest);

    // サーバーにアップロード（バックグラウンド）
    try {
      final bytes = await File(dest).readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _authService.uploadAvatar(b64);
    } catch (e) {
      debugPrint('avatar upload failed: $e');
    }
  }

  void _showImagePicker(CamillColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: colors.primary,
              ),
              title: Text(
                'ライブラリから選ぶ',
                style: camillBodyStyle(15, colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: colors.primary),
              title: Text(
                'カメラで撮る',
                style: camillBodyStyle(15, colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.danger),
                title: Text('写真を削除', style: camillBodyStyle(15, colors.danger)),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await UserPrefs.remove(prefs, _avatarPathKey);
                  if (mounted) setState(() => _avatarPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save(CamillColors colors) async {
    setState(() => _saving = true);
    try {
      final newName = _nameCtrl.text.trim();
      final newEmail = _emailCtrl.text.trim();
      final newRealName = _realNameCtrl.text.trim();
      final newPhone = _phoneCtrl.text.trim();

      // Firebase: 表示名の更新
      if (newName.isNotEmpty && newName != (_user?.displayName ?? '')) {
        await _authService.updateDisplayName(newName);
      }

      // Firebase: メールアドレスの更新
      if (newEmail.isNotEmpty && newEmail != (_user?.email ?? '')) {
        try {
          await _authService.verifyBeforeUpdateEmail(newEmail);
          if (mounted) {
            showTopNotification(context, '$newEmail に確認メールを送信しました');
          }
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          final msg = e.code == 'requires-recent-login'
              ? '再度ログインしてからメールアドレスを変更してください'
              : 'メールアドレスの変更に失敗しました';
          showTopNotification(context, msg);
          setState(() => _saving = false);
          return;
        }
      }

      // バックエンド: 本名・電話番号の更新
      await _authService.updateProfile(
        displayName: newName.isNotEmpty ? newName : null,
        realName: newRealName,
        phone: newPhone,
      );

      if (mounted) {
        showTopNotification(context, '保存しました');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('既に使用')
            ? 'この電話番号は既に登録されています'
            : '保存に失敗しました';
        showTopNotification(context, msg);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = (_user?.displayName ?? 'U').isNotEmpty
        ? (_user!.displayName![0]).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'アカウントの設定',
          style: camillHeadingStyle(17, colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(colors),
            child: Text(
              '保存',
              style: camillBodyStyle(
                15,
                colors.primary,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  // プロフィール画像
                  _CardLabel(
                    icon: Icons.person_outline,
                    title: 'プロフィール画像',
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  CamillCard(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _showImagePicker(colors),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: colors.primaryLight,
                              backgroundImage: _avatarPath != null
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: _avatarPath == null
                                  ? Text(
                                      initials,
                                      style: camillHeadingStyle(
                                        36,
                                        colors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.background,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: colors.fabIcon,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 本名
                  _CardLabel(
                    icon: Icons.account_circle_outlined,
                    title: '本名',
                    colors: colors,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'アプリ内では表示名が使われます。本名はアカウント管理用です。',
                      style: camillBodyStyle(11, colors.textMuted),
                    ),
                  ),
                  CamillCard(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _InputField(
                      controller: _realNameCtrl,
                      hint: '山田 太郎',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 表示名
                  _CardLabel(
                    icon: Icons.badge_outlined,
                    title: '表示名',
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  CamillCard(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _InputField(
                      controller: _nameCtrl,
                      hint: '名前を入力',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 電話番号
                  _CardLabel(
                    icon: Icons.phone_outlined,
                    title: '電話番号',
                    colors: colors,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'ファミリープランでの本人確認等に使用されます。',
                      style: camillBodyStyle(11, colors.textMuted),
                    ),
                  ),
                  CamillCard(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _InputField(
                      controller: _phoneCtrl,
                      hint: '090-0000-0000',
                      keyboardType: TextInputType.phone,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // メールアドレス
                  _CardLabel(
                    icon: Icons.mail_outline,
                    title: 'メールアドレス',
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  CamillCard(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InputField(
                          controller: _emailCtrl,
                          hint: 'メールアドレスを入力',
                          keyboardType: TextInputType.emailAddress,
                          colors: colors,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '変更すると新しいアドレスに確認メールが届きます',
                          style: camillBodyStyle(11, colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final CamillColors colors;

  const _CardLabel({
    required this.icon,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: camillBodyStyle(13, colors.textMuted, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final CamillColors colors;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceBorder, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: camillBodyStyle(16, colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: camillBodyStyle(16, colors.textMuted.withAlpha(100)),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
