import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../../../shared/services/api_service.dart';

class DriveExportService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  final ApiService _api = ApiService();

  Future<bool> get isSignedIn => _googleSignIn.isSignedIn();
  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// レシートデータをGoogle Driveにエクスポートする
  /// [yearMonth] は "YYYY-MM" 形式。null の場合は全期間
  /// [onStep] は進捗コールバック (現在ステップ index, ラベル)
  Future<String> exportToDrive({
    String? yearMonth,
    void Function(int step, String label)? onStep,
  }) async {
    // サインイン
    onStep?.call(0, 'Googleにサインイン中...');
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) throw Exception('Googleサインインがキャンセルされました');

    final auth = await account.authentication;
    if (auth.accessToken == null) throw Exception('アクセストークンの取得に失敗しました');

    final client = _GoogleAuthClient(auth.accessToken!);

    try {
      final driveApi = drive.DriveApi(client);

      // バックエンドからデータ取得
      onStep?.call(1, 'データを取得中...');
      final endpoint = yearMonth != null
          ? '/receipts/export?year_month=$yearMonth'
          : '/receipts/export';
      final data = await _api.get(endpoint);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonStr);

      // ファイル名決定
      final fileName = yearMonth != null
          ? 'camill_receipts_$yearMonth.json'
          : 'camill_receipts_all.json';

      // camillフォルダを取得 or 作成
      onStep?.call(2, 'Driveフォルダを確認中...');
      final folderId = await _getOrCreateFolder(driveApi);

      // 既存ファイル検索（上書き更新）
      final existing = await driveApi.files.list(
        q: "name='$fileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
      );

      onStep?.call(3, 'アップロード中...');
      final stream = Stream.fromIterable([bytes]);
      final media = drive.Media(
        stream,
        bytes.length,
        contentType: 'application/json',
      );

      String fileId;
      if (existing.files?.isNotEmpty == true) {
        final updated = await driveApi.files.update(
          drive.File(),
          existing.files!.first.id!,
          uploadMedia: media,
        );
        fileId = updated.id ?? '';
      } else {
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'application/json';
        final created = await driveApi.files.create(
          file,
          uploadMedia: media,
        );
        fileId = created.id ?? '';
      }

      onStep?.call(4, '完了');
      return fileId;
    } finally {
      client.close();
    }
  }

  Future<String> _getOrCreateFolder(drive.DriveApi driveApi) async {
    const folderName = 'camill';
    final result = await driveApi.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    if (result.files?.isNotEmpty == true) {
      return result.files!.first.id!;
    }
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder);
    return created.id!;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
