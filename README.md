# Sotto

A multiplatform subscription tracker for iOS, iPadOS, and macOS. Sotto helps you keep tabs on recurring charges — what you pay, when it renews, and how it adds up across categories and currencies.

## Features

- Track subscriptions with name, icon, amount, currency, and billing cycle (weekly, monthly, quarterly, half-yearly, yearly).
- Dashboard with monthly / yearly spending totals, category breakdown chart, and upcoming renewals.
- Calendar view of upcoming due dates.
- Categories and payment methods to organize subscriptions.
- Multi-currency support with live exchange rate conversion to a chosen base currency.
- Inspector pane for quick edits, plus payment history per subscription.

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData
- **Targets:** iOS 19.0+, macOS 26.0+
- **Project generation:** [Tuist](https://tuist.io) (`Project.swift`)

## Getting Started

```bash
tuist generate
open Sotto.xcworkspace
```

Build and run the `Sotto` scheme.

## Project Layout

```
Sotto/
├── App/           # App entry point
├── Models/        # SwiftData models (Subscription, Category, PaymentMethod, …)
├── Services/      # BillingCycleCalculator, CurrencyService
├── Views/         # Dashboard, Calendar, Subscriptions, Categories, Sidebar, Settings, Components
└── Extensions/    # Model conveniences
```
