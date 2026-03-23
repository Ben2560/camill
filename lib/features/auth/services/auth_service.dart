import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // メール + パスワードで新規登録
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
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
      String verificationId, String smsCode) async {
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
    await _api.post('/auth/register', body: {
      'uid': user.uid,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'onboarding_type': {
        'priorities': ['food', 'daily', 'other'],
        'monthly_budget': {'food': 30000, 'daily': 10000},
      },
    });
  }

  // 表示名を更新
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // パスワード再設定メール送信
  Future<void> sendPasswordResetEmail() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      await _auth.sendPasswordResetEmail(email: email);
    }
  }

  // アカウント削除（バックエンド + Firebase）
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _api.delete('/auth/me');
    } catch (_) {}
    await user.delete();
  }

  Future<void> signOut() => _auth.signOut();
}
