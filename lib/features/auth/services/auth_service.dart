import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/notification_inbox.dart';
import '../../../shared/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Googleサインイン（新規登録 or ログイン）
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      scopes: ['email', 'profile'],
    ).signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureBackendUser(result);
    return result;
  }

  // Appleサインイン（新規登録 or ログイン）
  Future<UserCredential> signInWithApple() async {
    final nonce = _generateNonce();
    final hashedNonce = _sha256(nonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: nonce);

    final result = await _auth.signInWithCredential(oauthCredential);

    // Appleは初回のみ名前を返すのでFirebaseプロフィールに反映
    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    if (givenName != null || familyName != null) {
      final name = [familyName, givenName].whereType<String>().join('');
      if (name.isNotEmpty) {
        await result.user?.updateDisplayName(name);
      }
    }

    await _ensureBackendUser(result);
    return result;
  }

  // ソーシャルログイン後にバックエンドにユーザーを登録（未登録の場合のみ）
  Future<void> _ensureBackendUser(UserCredential credential) async {
    final user = credential.user;
    if (user == null) return;
    final isNew = credential.additionalUserInfo?.isNewUser ?? false;
    if (!isNew) return;
    await _api.post(
      '/auth/register',
      body: {
        'uid': user.uid,
        'email': user.email ?? '',
        'display_name':
            user.displayName ?? user.email?.split('@').first ?? 'ユーザー',
        'onboarding_type': {
          'priorities': ['food', 'daily', 'other'],
          'monthly_budget': {'food': 30000, 'daily': 10000},
        },
      },
    );
  }

  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // メール + パスワードで新規登録
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // メール + パスワードでログイン
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 電話番号SMS認証の開始
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String, int?) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // SMS認証コードで電話番号をリンク
  Future<void> linkPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.currentUser?.linkWithCredential(credential);
  }

  // バックエンドにユーザー登録
  Future<void> registerUserInBackend({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _api.post(
      '/auth/register',
      body: {
        'uid': user.uid,
        'email': email,
        'phone': phone,
        'display_name': displayName,
        'onboarding_type': {
          'priorities': ['food', 'daily', 'other'],
          'monthly_budget': {'food': 30000, 'daily': 10000},
        },
      },
    );
  }

  // 表示名を更新
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // プロフィール（本名・電話番号）をバックエンドに更新
  Future<void> updateProfile({
    String? displayName,
    String? realName,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (realName != null) body['real_name'] = realName;
    if (phone != null) body['phone'] = phone;
    if (body.isEmpty) return;
    await _api.patch('/auth/me', body: body);
  }

  // バックエンドからプロフィール取得
  Future<Map<String, dynamic>> fetchProfile() async {
    final res = await _api.get('/auth/me');
    return Map<String, dynamic>.from(res as Map);
  }

  // アバター画像をサーバーにアップロード（Base64形式）
  Future<void> uploadAvatar(String base64Data) async {
    await _api.put('/auth/avatar', body: {'avatar_data': base64Data});
  }

  // パスワード再設定メール送信
  Future<void> sendPasswordResetEmail() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
    }
  }

  // メールアドレス変更（新アドレスに確認メール送信）
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }

  // プロフィール画像URLを更新
  Future<void> updatePhotoURL(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
  }

  // アカウント削除（バックエンド + Firebase）
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _api.delete('/auth/me');
    } catch (e) {
      debugPrint('deleteAccount API call failed: $e');
    }
    await user.delete();
  }

  Future<void> signOut() async {
    await NotificationService().unregisterToken();
    NotificationInbox().reset();
    // UIDプレフィックスなしのキー（CacheService等）を削除して次のアカウントへの漏洩を防ぐ
    final prefs = await SharedPreferences.getInstance();
    final staleKeys = prefs
        .getKeys()
        .where((k) => !k.startsWith('uid_') && !k.startsWith('flutter.'))
        .toList();
    for (final k in staleKeys) {
      await prefs.remove(k);
    }
    await _auth.signOut();
  }
}
