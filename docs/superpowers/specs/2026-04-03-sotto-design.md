# Sotto — Design Specification

**Date:** 2026-04-03
**Status:** Draft
**Platform:** macOS 14+

---

## Overview

Sotto is a native macOS app for tracking all recurring expenses — digital subscriptions and recurring bills — in one place. It provides a dashboard-focused experience with at-a-glance spending insights, upcoming renewal alerts, and multi-currency support with automatic conversion.

### Tech Stack
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData with CloudKit
- **Sync:** iCloud
- **Currency API:** frankfurter.app (free, no API key)
- **Minimum Deployment:** macOS 14.0

---

## Data Model

### Subscription
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Subscription name |
| icon | String | SF Symbol name or emoji |
| amount | Decimal | Cost in original currency |
| currencyCode | String | ISO currency code (USD, CNY, EUR, etc.) |
| billingCycle | Enum | `weekly`, `monthly`, `quarterly`, `yearly` |
| startDate | Date | When the subscription began |
| nextDueDate | Date | Next payment date (auto-calculated) |
| category | Category | Relationship to category |
| paymentMethod | PaymentMethod? | Optional relationship |
| status | Enum | `active`, `paused`, `cancelled` |
| notes | String? | Free-form notes |
| createdAt | Date | Record creation timestamp |
| updatedAt | Date | Last modification timestamp |

### Category
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Display name (e.g., "Streaming", "Utilities") |
| color | String | Hex color for charts and badges |
| icon | String | SF Symbol name |

### PaymentMethod
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Display name (e.g., "Chase Visa", "PayPal") |
| type | Enum | `credit`, `debit`, `bank`, `other` |

### PaymentHistory
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| subscription | Subscription | Relationship to subscription |
| paidDate | Date | When payment occurred |
| amount | Decimal | Amount paid |
| currencyCode | String | Currency at time of payment |

### ExchangeRate (Cached)
| Field | Type | Description |
|-------|------|-------------|
| baseCurrency | String | User's display currency |
| rates | [String: Double] | Currency code → rate mapping |
| lastUpdated | Date | Cache timestamp (invalidate after 24h) |

---

## UI Structure

### Window Layout
Three-column sidebar pattern following macOS conventions:

```
┌─────────────────────────────────────────────────────────────┐
│  Sotto                                          ─ □ ×      │
├────────────┬──────────────────────────────┬────────────────┤
│  Sidebar   │      Main Content Area       │  Inspector     │
│            │                              │  (optional)    │
│  ──────────│                              │                │
│  Navigation│  Changes based on            │  Shows detail  │
│  ──────────│  sidebar selection           │  for selected  │
│  Quick Stats│                             │  item          │
│            │                              │                │
└────────────┴──────────────────────────────┴────────────────┘
```

### Sidebar
**Navigation Section:**
- Dashboard
- All Subscriptions
- Calendar
- Categories
- Settings

**Quick Stats Section:**
- This month's total (converted to base currency)
- Count of upcoming renewals

### Main Content Views

| View | Description |
|------|-------------|
| Dashboard | Primary view with spending overview, category chart, upcoming renewals, recent activity |
| All Subscriptions | Searchable, sortable list with filters (status, category, payment method) |
| Calendar | Month grid with renewal dates marked; click date to see that day's subscriptions |
| Categories | Manage categories, view spend breakdown per category |
| Settings | Base currency selection, notification preferences, iCloud sync status |

### Inspector Pane
- Appears when a subscription is selected in list or calendar
- Shows full subscription details and payment history timeline
- Quick actions: pause, cancel, edit, record payment

---

## Features

### Dashboard Widgets

**Spending Overview**
- Large display of monthly total in base currency
- Year-over-year comparison (if historical data exists)

**Category Breakdown**
- Donut chart showing spend distribution
- Legend with category names and amounts
- Click segment to filter subscriptions by category

**Upcoming Renewals**
- List of next 5 subscriptions due
- Days-until badge for each (e.g., "2 days")
- Visual highlight for urgent (within 3 days)

**Recent Activity**
- Last 5 recorded payments
- Subscription name, amount, date

### Adding Subscriptions
- Toolbar "+" button opens a sheet
- Form fields: name, icon picker, amount, currency selector, billing cycle, start date, category picker, payment method picker, notes
- Next due date auto-calculated from start date + billing cycle
- Validation: required fields (name, amount, currency, billing cycle, start date, category)

### Currency Handling
- User selects base currency in Settings (default: system locale)
- Each subscription stores original currency and amount
- Dashboard totals show converted values in base currency
- Exchange rates cached in SwiftData, refreshed on app launch if older than 24 hours
- Offline fallback: use cached rates with "updated X hours ago" indicator
- API: frankfurter.app — free, no authentication, supports 30+ currencies

### In-App Notifications
- Badge on sidebar showing count of subscriptions due within 3 days
- "Upcoming Renewals" widget highlights urgent items
- No system push notifications — all visual within the app

### Payment Recording
- "Mark as Paid" action in inspector pane or context menu
- Creates PaymentHistory entry with current date and amount
- Automatically advances nextDueDate by one billing cycle

### Status Management
- **Active:** Normal tracking, included in totals, renewal alerts enabled
- **Paused:** Visible in list, excluded from totals, no renewal alerts
- **Cancelled:** Moved to archive filter, retained for payment history

---

## Project Structure

```
Sotto/
├── App/
│   └── SottoApp.swift              # App entry, SwiftData container setup
├── Models/
│   ├── Subscription.swift
│   ├── Category.swift
│   ├── PaymentMethod.swift
│   ├── PaymentHistory.swift
│   └── ExchangeRate.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── SubscriptionListViewModel.swift
│   └── ExchangeRateService.swift
├── Views/
│   ├── ContentView.swift           # Main window, sidebar navigation
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── SpendingCard.swift
│   │   ├── CategoryChart.swift
│   │   └── UpcomingRenewals.swift
│   ├── Subscriptions/
│   │   ├── SubscriptionListView.swift
│   │   ├── SubscriptionRow.swift
│   │   └── SubscriptionDetailView.swift
│   ├── Calendar/
│   │   └── CalendarView.swift
│   ├── Categories/
│   │   └── CategoriesView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── AddSubscriptionSheet.swift
│       └── InspectorPane.swift
├── Services/
│   └── CurrencyConverter.swift
├── Extensions/
│   └── Color+Hex.swift
└── Resources/
    └── Assets.xcassets
```

---

## Technical Notes

### SwiftData + CloudKit
- Use `@Model` macro for all entities
- Enable CloudKit via `.cloudKitContainerIdentifier("iCloud.com.yourdomain.sotto")`
- Schema defined in code — no manual migration for v1

### Exchange Rate Service
- Endpoint: `https://api.frankfurter.app/latest?from={baseCurrency}`
- Response: `{ "rates": { "EUR": 0.92, "GBP": 0.79, ... } }`
- Cache in ExchangeRate entity, check lastUpdated before refresh
- Handle network errors gracefully with cached fallback

### Date Calculations
- Billing cycle logic centralized in a helper
- Weekly: +7 days
- Monthly: +1 month (calendar-aware)
- Quarterly: +3 months
- Yearly: +1 year

### Default Data
- Pre-populate 8-10 common categories on first launch:
  - Streaming, Software, Cloud Storage, Gaming, News & Media, Utilities, Health & Fitness, Other
- Default payment methods: none (user creates their own)

---

## Scope Boundaries

### In Scope (v1)
- Add/edit/delete subscriptions
- Dashboard with widgets
- Multi-currency with auto-conversion
- iCloud sync
- Payment history tracking
- Status management (active/paused/cancelled)
- Calendar view
- Category management

### Out of Scope (Future)
- iOS companion app
- System notifications
- Data export (CSV/JSON)
- Budget limits/alerts
- Shared subscriptions (family tracking)
- Price change detection
