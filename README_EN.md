# Camill

A household finance app for families — just snap a receipt and you're done.

---

## What is this?

It started from a simple frustration: manually tracking expenses in a household ledger is tedious and doesn't really help you save money. Point your camera at a receipt and the AI reads the items, amounts, and categories automatically. Medical bills, utility invoices, and regular receipts all go through the same flow, so snapping a few receipts from your wallet is basically enough to know where your money went this month.

The Family Plan lets you split spending by wallet per family member, so you can keep an eye on your partner's and kids' expenses all in one place.

---

## Features

### Receipt & Document Scanning

- Shoot from camera or gallery → AI auto-detects items, amounts, and categories
- Separate input flows for regular receipts, medical bills, and invoices
- Auto-detection of uncovered medical expenses (self-pay) with badge display
- Grouped display for identical items (`×N` badge)
- Up to 3 automatic retries on analysis failure (exponential backoff)
- Manual entry form also available

### Budget & Expense Tracking

- Per-category budget settings with progress bars
- Calendar view for day-by-day spending
- Monthly, weekly, and yearly summaries
- Automatic consumption tax estimation (tax-exempt items excluded)
- Savings tracking — discounts and coupons are tallied automatically

### Invoice Management

- Alert banner for unpaid invoices (red highlight within 3 days)
- Automatic "paid" detection from stamps and seals on invoices
- Public utility bills and taxes excluded from tax calculations

### Coupon Wallet

- Auto-detection of reusable coupons from receipts
- Push notifications for coupons expiring soon
- Community feature to share nearby users' coupon info

### Family Plan

- Invite family members via QR code
- Wallet rules to split and assign expenses
- Partner spending summary and children's monthly expenses on the home screen
- Per-member view permissions

### Reports & Analytics

- Monthly AI-generated spending commentary (premium only)
- Configurable day of week for weekly reports
- Top stores ranking and scan count statistics

### Miscellaneous

- FCM push notifications (invoice reminders, coupon expiry, budget alerts)
- Automatic dark mode based on sunrise / sunset times
- Drag-to-reorder home screen widgets
- Profile picture that survives app container UUID changes (iOS updates, restores)

---

## Plans

| Plan | Price | Scans |
| --- | --- | --- |
| Free | Free | Limited |
| Pro (monthly) | ¥480/mo | 50/month |
| Pro (annual) | ¥4,600/yr | 60/month |
| Family (monthly) | ¥980/mo | 150/month (shared) |
| Family (annual) | ¥11,100/yr | 200/month (shared) |

First month free trial available.

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile app | Flutter (iOS / Android) |
| Backend API | FastAPI (Python) |
| Admin panel | Next.js |
| Auth | Firebase Auth |
| Push notifications | Firebase Cloud Messaging (FCM) |
| AI analysis | Google Gemini |
| Billing | App Store IAP / Google Play Billing |
| Scheduler | APScheduler (JST) |

---

## Directory Structure

```text
camill/           # Flutter app (this repo)
camill-api/       # FastAPI backend
camill-admin-web/ # Next.js admin panel
```

### Flutter App Structure

```text
lib/
├── main.dart                     # Entry point, GoRouter config
├── core/
│   ├── constants.dart            # API URLs, category definitions
│   └── theme/                    # Themes (Sakura / Morning / Forest / Midnight, etc.)
├── features/                     # Feature modules
│   ├── auth/                     # Login, registration, phone verification
│   ├── shell/                    # Bottom nav, speed dial
│   ├── home/                     # Dashboard, spending chart
│   ├── receipt/                  # Camera, OCR results, editing
│   ├── calendar/                 # Calendar view
│   ├── coupon/                   # Coupon management
│   ├── bill/                     # Invoice management
│   ├── community/                # Community, maps
│   ├── family/                   # Family management, QR invite
│   ├── reports/                  # Monthly reports
│   └── profile/                  # Profile, plan, settings
└── shared/
    ├── models/                   # Data models
    ├── services/api_service.dart # HTTP client with Firebase auth token
    └── widgets/                  # Shared UI components
```

---

## Setup

### Requirements

- Flutter SDK
- Firebase project (`google-services.json` / `GoogleService-Info.plist`)
- Backend API running separately (`camill-api/`)

### Run the App

```bash
# Install dependencies
flutter pub get

# Run on a device or simulator
flutter run
```

The API base URL is configured in `lib/core/constants.dart` → `baseUrl`.

---

## Running the Backend

```bash
cd camill-api
pip install -r requirements.txt
uvicorn app.main:app --reload
```

See the config files under `camill-api/` for environment variable setup.

---

## Running the Admin Panel

```bash
cd camill-admin-web
npm install
npm run dev
```

Or use `admin.sh`, which also handles automatic IP address updates.
