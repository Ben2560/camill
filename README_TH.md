# Camill

แอปจัดการการเงินในครัวเรือนสำหรับครอบครัว — แค่ถ่ายใบเสร็จก็เสร็จแล้ว

---

## แอปนี้คืออะไร?

เริ่มต้นจากความรู้สึกว่าการจดบัญชีครัวเรือนด้วยมือนั้นยุ่งยากและไม่ได้ช่วยให้ประหยัดขึ้นจริง แค่เอากล้องจ่อที่ใบเสร็จ AI จะอ่านรายการ จำนวนเงิน และหมวดหมู่ให้เองโดยอัตโนมัติ ใบเสร็จทางการแพทย์ ค่าสาธารณูปโภค และใบเสร็จทั่วไปก็ใช้ขั้นตอนเดียวกัน แค่ถ่ายใบเสร็จในกระเป๋าสตางค์ทั้งหมด ก็รู้แล้วว่าเดือนนี้เงินหายไปไหน

แผน Family ช่วยให้แยก wallet ตามสมาชิกแต่ละคน ดูค่าใช้จ่ายของคู่ครองและลูกๆ ได้ในที่เดียว

---

## ฟีเจอร์หลัก

### สแกนใบเสร็จและเอกสาร

- ถ่ายจากกล้องหรือแกลเลอรี่ → AI วิเคราะห์รายการ ราคา และหมวดหมู่อัตโนมัติ
- แบบฟอร์มแยกสำหรับใบเสร็จทั่วไป ใบเสร็จทางการแพทย์ และใบแจ้งหนี้
- ตรวจจับค่ารักษาพยาบาลนอกระบบประกัน (จ่ายเอง) อัตโนมัติ พร้อมแสดง badge
- รวมรายการที่ซ้ำกันไว้ด้วยกัน (`×N` badge)
- ลองวิเคราะห์ซ้ำอัตโนมัติสูงสุด 3 ครั้งหากเกิดข้อผิดพลาด (exponential backoff)
- มีฟอร์มกรอกด้วยมือด้วย

### การจัดการงบประมาณและค่าใช้จ่าย

- ตั้งงบประมาณแต่ละหมวดหมู่พร้อม progress bar
- ดูค่าใช้จ่ายรายวันในมุมมองปฏิทิน
- สรุปรายเดือน รายสัปดาห์ และรายปี
- คำนวณภาษีมูลค่าเพิ่มโดยอัตโนมัติ (ยกเว้นรายการที่ได้รับยกเว้นภาษี)
- นับยอดเงินที่ประหยัดได้จากส่วนลดและคูปองโดยอัตโนมัติ

### จัดการใบแจ้งหนี้

- แบนเนอร์แจ้งเตือนใบแจ้งหนี้ที่ยังค้างชำระ (ไฮไลต์สีแดงหากครบกำหนดภายใน 3 วัน)
- ตรวจจับสถานะ "ชำระแล้ว" จากตราประทับบนเอกสารอัตโนมัติ
- ยกเว้นค่าสาธารณูปโภคและภาษีออกจากการคำนวณ VAT

### คลังคูปอง

- ตรวจจับคูปองที่ใช้ได้ครั้งต่อไปจากใบเสร็จอัตโนมัติ
- แจ้งเตือน push เมื่อคูปองใกล้หมดอายุ
- ฟีเจอร์ Community สำหรับแชร์ข้อมูลคูปองกับผู้ใช้ใกล้เคียง

### แผนครอบครัว

- เชิญสมาชิกในครอบครัวด้วย QR code
- ตั้งกฎ wallet เพื่อแยกและกำหนดค่าใช้จ่าย
- แสดงสรุปค่าใช้จ่ายของคู่ครองและลูกๆ บนหน้าหลัก
- จัดการสิทธิ์การดูข้อมูลแยกตามสมาชิก

### รายงานและการวิเคราะห์

- AI สรุปการใช้จ่ายรายเดือน (เฉพาะ premium)
- กำหนดวันในสัปดาห์สำหรับรายงานรายสัปดาห์ได้
- อันดับร้านค้าที่ใช้บ่อยและสถิติจำนวนการสแกน

### อื่นๆ

- การแจ้งเตือน FCM push (เตือนใบแจ้งหนี้ คูปองหมดอายุ งบประมาณเกิน)
- สลับ dark mode อัตโนมัติตามเวลาพระอาทิตย์ขึ้น/ตก
- ลากเพื่อเรียงลำดับ widget บนหน้าหลัก
- รูปโปรไฟล์ที่ไม่หายแม้จะอัปเดตแอปหรือกู้คืนข้อมูล (iOS UUID)

---

### โครงสร้าง

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
│   │   │   ├── community_screen.dart
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
