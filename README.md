# Camill

レシートを撮るだけで家計が整う、家族向け家計管理アプリです。

---

## どんなアプリか

「いちいち手書きで家計簿をつけるのが面倒だし節約にならない」といった問題を解決するところから始まりました。カメラを向けるだけでAIが品目・金額・カテゴリを読み取り、あとは勝手に集計してくれます。医療明細や請求書（光熱費・税金など）も同じフローで登録できるので、財布の中のレシートをまとめて撮るだけで今月の支出がほぼ把握できます。

ファミリープランでは家族ごとにウォレットを分けて管理でき、パートナーや子供の支出もまとめて見られます。

---

## 主な機能

### レシート・明細管理

- カメラまたはギャラリーから撮影 → AIが品目・金額・カテゴリを自動解析
- 医療明細・請求書・通常レシートをそれぞれ最適なフォームで登録
- 自由診療（保険外）の自動検出とバッジ表示
- 同一品目のグループ折りたたみ表示（`×N`バッジ）
- 解析失敗時は最大3回まで自動リトライ（指数バックオフ）
- 手動入力フォームも完備

### 予算・支出管理

- カテゴリ別予算設定と進捗バー
- カレンダービューで日ごとの支出確認
- 月次・週次・年次のサマリー集計
- 消費税の自動推定（非課税品目は除外）
- 節約額の自動集計と表示（割引・クーポン分）

### 請求書管理

- 未払い請求書のアラートバナー（3日以内は赤色強調）
- 印鑑・スタンプから支払済みを自動判定
- 公共料金・税金は消費税計算から自動除外

### クーポン管理

- レシートから次回利用できるクーポンを自動検出
- 有効期限が近いクーポンのプッシュ通知
- コミュニティ機能で近くのユーザーのクーポン情報を共有

### ファミリープラン

- QRコードでメンバー招待
- ウォレット機能で支出の振り分けルール設定
- パートナーの支出サマリー・子供の今月支出をホームに表示
- メンバーごとの閲覧権限管理

### レポート・分析

- 月次AIコメント（プレミアムのみ）
- 週次レポートの曜日設定
- 上位店舗ランキング・スキャン枚数統計

### その他

- FCMプッシュ通知（請求書リマインダー・クーポン期限・予算超過アラート）
- 日の出・日の入りベースの自動ダークモード切替
- ホーム画面のウィジェット並び替え（ドラッグ）
- プロフィール画像（アプリコンテナUUID変更にも対応）

---

### 構造

```text
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   └── theme/
│       ├── camill_colors.dart
│       ├── camill_theme.dart
│       ├── camill_theme_mode.dart
│       ├── theme_provider.dart
│       └── sun_times.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── phone_verify_screen.dart
│   │   │   └── register_screen.dart
│   │   └── services/auth_service.dart
│   ├── bill/
│   │   ├── screens/bill_screen.dart
│   │   └── services/bill_service.dart
│   ├── calendar/
│   │   ├── screens/calendar_screen.dart
│   │   └── widgets/
│   │       ├── calendar_bill_detail_sheet.dart
│   │       ├── calendar_coupon_action_sheet.dart
│   │       ├── calendar_day_panel.dart
│   │       └── calendar_receipt_detail_sheet.dart
│   ├── community/
│   │   ├── screens/
│   │   │   ├── community_screen.dart       # Google Maps
│   │   │   └── community_settings_screen.dart
│   │   ├── services/community_service.dart
│   │   └── widgets/
│   │       ├── community_store_sheet.dart
│   │       ├── map_styles.dart
│   │       └── store_card.dart
│   ├── coupon/
│   │   ├── screens/coupon_wallet_screen.dart
│   │   ├── services/coupon_service.dart
│   │   └── widgets/coupon_card_widgets.dart
│   ├── data/
│   │   ├── screens/data_screen.dart
│   │   └── widgets/data_chart_widgets.dart
│   ├── family/
│   │   ├── screens/
│   │   │   ├── family_invite_screen.dart
│   │   │   ├── family_join_screen.dart
│   │   │   ├── family_management_screen.dart
│   │   │   └── wallet_management_screen.dart
│   │   └── services/
│   │       ├── family_service.dart
│   │       └── wallet_service.dart
│   ├── home/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── category_budget_screen.dart
│   │   │   └── fixed_expense_scan_screen.dart
│   │   ├── services/fixed_expense_service.dart
│   │   └── widgets/
│   │       ├── home_bill_detail_sheet.dart
│   │       ├── home_month_page.dart
│   │       ├── notification_inbox_sheet.dart
│   │       ├── overseas_rate_card.dart
│   │       ├── subscription_editor_sheet.dart
│   │       ├── tax_breakdown_row.dart
│   │       └── today_coupon_sheet.dart
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── account_settings_screen.dart
│   │   │   ├── income_settings_screen.dart
│   │   │   ├── notification_settings_screen.dart
│   │   │   ├── plan_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── support_detail_screen.dart
│   │   │   ├── support_screen.dart
│   │   │   └── theme_settings_screen.dart
│   │   └── services/
│   │       ├── drive_export_service.dart
│   │       └── purchase_service.dart
│   ├── receipt/
│   │   ├── screens/
│   │   │   ├── analysis_preview_screen.dart
│   │   │   ├── camera_screen.dart
│   │   │   ├── manual_input_screen.dart
│   │   │   ├── receipt_edit_screen.dart
│   │   │   └── receipt_list_screen.dart
│   │   ├── services/receipt_service.dart
│   │   └── widgets/
│   │       ├── receipt_form_page.dart
│   │       └── receipt_form_widgets.dart
│   ├── reports/screens/report_screen.dart
│   ├── shell/main_shell.dart
│   └── subscriptions/screens/subscription_screen.dart
└── shared/
    ├── models/
    │   ├── bill_model.dart
    │   ├── community_model.dart
    │   ├── coupon_model.dart
    │   ├── family_model.dart
    │   ├── fixed_expense_model.dart
    │   ├── receipt_model.dart
    │   ├── summary_model.dart
    │   └── wallet_model.dart
    ├── services/
    │   ├── api_service.dart
    │   ├── notification_inbox.dart
    │   ├── notification_service.dart
    │   ├── overseas_service.dart
    │   └── user_prefs.dart
    └── widgets/
        ├── animated_counter.dart
        ├── budget_sheet.dart
        ├── camill_card.dart
        ├── loading_overlay.dart
        ├── month_greeting_overlay.dart
        ├── pull_to_refresh.dart
        └── top_notification.dart
```

---

### 開発者から一言

- 頑張ります。以上です。
