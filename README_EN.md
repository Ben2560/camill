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
