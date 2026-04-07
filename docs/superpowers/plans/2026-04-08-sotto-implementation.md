# Sotto Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS subscription tracker with dashboard, multi-currency support, calendar view, and iCloud sync using SwiftUI + SwiftData.

**Architecture:** Three-column NavigationSplitView with sidebar navigation, main content area, and optional inspector pane. SwiftData models with CloudKit backing. Currency conversion via frankfurter.app with local caching. MVVM-lite — SwiftUI views query SwiftData directly via `@Query`, with dedicated service types for currency conversion and date calculations.

**Tech Stack:** Swift 6.3, SwiftUI, SwiftData, CloudKit, XcodeGen, macOS 14+

---

## File Structure

```
Sotto/
├── project.yml                          # XcodeGen project spec
├── Sotto/
│   ├── App/
│   │   └── SottoApp.swift               # @main, ModelContainer setup, window config
│   ├── Models/
│   │   ├── Subscription.swift           # @Model, billing cycle enum, status enum
│   │   ├── Category.swift               # @Model, color/icon
│   │   ├── PaymentMethod.swift          # @Model, type enum
│   │   ├── PaymentHistory.swift         # @Model, links to Subscription
│   │   └── ExchangeRate.swift           # @Model, cached rates dictionary
│   ├── Services/
│   │   ├── CurrencyService.swift        # Fetch & cache exchange rates, convert amounts
│   │   └── BillingCycleCalculator.swift # Next due date, cycle math
│   ├── Views/
│   │   ├── ContentView.swift            # NavigationSplitView, sidebar, inspector
│   │   ├── Sidebar/
│   │   │   └── SidebarView.swift        # Navigation links + quick stats
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift      # Grid of dashboard widgets
│   │   │   ├── SpendingCard.swift       # Monthly total display
│   │   │   ├── CategoryChart.swift      # Donut chart via Swift Charts
│   │   │   └── UpcomingRenewalsCard.swift # Next 5 due subscriptions
│   │   ├── Subscriptions/
│   │   │   ├── SubscriptionListView.swift   # Searchable, filterable list
│   │   │   ├── SubscriptionRow.swift        # Row in the list
│   │   │   └── AddSubscriptionSheet.swift   # Form sheet for add/edit
│   │   ├── Calendar/
│   │   │   └── CalendarView.swift       # Month grid with renewal markers
│   │   ├── Categories/
│   │   │   └── CategoriesView.swift     # Category management
│   │   ├── Settings/
│   │   │   └── SettingsView.swift       # Base currency, sync status
│   │   └── Components/
│   │       ├── InspectorPane.swift      # Subscription detail + actions
│   │       ├── IconPicker.swift         # SF Symbol picker grid
│   │       └── CurrencyPicker.swift     # Currency code selector
│   └── Extensions/
│       └── Color+Hex.swift              # Init from hex string, to hex string
├── SottoTests/
│   ├── BillingCycleCalculatorTests.swift
│   ├── CurrencyServiceTests.swift
│   └── ModelTests.swift
└── Resources/
    └── Assets.xcassets/
        └── AccentColor.colorset/
            └── Contents.json
```

---

## Task 1: Project Scaffolding with XcodeGen

**Files:**
- Create: `Sotto/project.yml`
- Create: `Sotto/Sotto/App/SottoApp.swift`
- Create: `Sotto/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `Sotto/Resources/Assets.xcassets/Contents.json`
- Create: `Sotto/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `Sotto/Sotto.entitlements`

- [ ] **Step 1: Create the XcodeGen project spec**

```yaml
# Sotto/project.yml
name: Sotto
options:
  bundleIdPrefix: com.sotto
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "26.4"
  groupSortPosition: top
settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
targets:
  Sotto:
    type: application
    platform: macOS
    sources:
      - path: Sotto
        excludes:
          - "**/.DS_Store"
    resources:
      - path: Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sotto.app
        INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.finance"
        CODE_SIGN_ENTITLEMENTS: Sotto.entitlements
        PRODUCT_NAME: Sotto
    entitlements:
      path: Sotto.entitlements
  SottoTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: SottoTests
    dependencies:
      - target: Sotto
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sotto.app.tests
```

- [ ] **Step 2: Create the entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

Note: CloudKit entitlements (`com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services`) will be added later when an Apple Developer account is configured. For now, we use SwiftData without CloudKit sync to keep development simple.

- [ ] **Step 3: Create the minimal app entry point**

```swift
// Sotto/Sotto/App/SottoApp.swift
import SwiftUI
import SwiftData

@main
struct SottoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Subscription.self,
            Category.self,
            PaymentMethod.self,
            PaymentHistory.self,
            ExchangeRate.self
        ])
    }
}
```

Note: This will not compile until the models are defined in Task 2. That's expected.

- [ ] **Step 4: Create asset catalogs**

`Sotto/Resources/Assets.xcassets/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`Sotto/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.890",
          "green" : "0.459",
          "red" : "0.298"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`Sotto/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Create a placeholder ContentView**

```swift
// Sotto/Sotto/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Sotto")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 6: Generate Xcode project and verify build**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds (will fail until models exist — that's Task 2).

- [ ] **Step 7: Initialize git and commit**

```bash
cd /Users/gaowanqiu/Develop/sotto
git init
echo ".DS_Store\n*.xcodeproj\nxcuserdata/\nbuild/\nDerivedData/" > .gitignore
git add .
git commit -m "feat: scaffold Sotto project with XcodeGen"
```

---

## Task 2: Data Models

**Files:**
- Create: `Sotto/Sotto/Models/Subscription.swift`
- Create: `Sotto/Sotto/Models/Category.swift`
- Create: `Sotto/Sotto/Models/PaymentMethod.swift`
- Create: `Sotto/Sotto/Models/PaymentHistory.swift`
- Create: `Sotto/Sotto/Models/ExchangeRate.swift`

- [ ] **Step 1: Create Category model**

```swift
// Sotto/Sotto/Models/Category.swift
import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    @Relationship(deleteRule: .nullify, inverse: \Subscription.category)
    var subscriptions: [Subscription]

    init(name: String, colorHex: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.subscriptions = []
    }

    static let defaults: [(name: String, colorHex: String, icon: String)] = [
        ("Streaming", "#FF6B6B", "play.tv"),
        ("Software", "#4ECDC4", "laptopcomputer"),
        ("Cloud Storage", "#45B7D1", "cloud"),
        ("Gaming", "#96CEB4", "gamecontroller"),
        ("News & Media", "#FFEAA7", "newspaper"),
        ("Utilities", "#DDA0DD", "bolt"),
        ("Health & Fitness", "#98D8C8", "heart"),
        ("Other", "#B0B0B0", "ellipsis.circle")
    ]
}
```

- [ ] **Step 2: Create PaymentMethod model**

```swift
// Sotto/Sotto/Models/PaymentMethod.swift
import Foundation
import SwiftData

enum PaymentMethodType: String, Codable, CaseIterable {
    case credit
    case debit
    case bank
    case other
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: PaymentMethodType
    @Relationship(deleteRule: .nullify, inverse: \Subscription.paymentMethod)
    var subscriptions: [Subscription]

    init(name: String, type: PaymentMethodType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.subscriptions = []
    }
}
```

- [ ] **Step 3: Create Subscription model**

```swift
// Sotto/Sotto/Models/Subscription.swift
import Foundation
import SwiftData

enum BillingCycle: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        rawValue.capitalized
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active
    case paused
    case cancelled

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class Subscription {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var amount: Decimal
    var currencyCode: String
    var billingCycle: BillingCycle
    var startDate: Date
    var nextDueDate: Date
    var category: Category?
    var paymentMethod: PaymentMethod?
    var status: SubscriptionStatus
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PaymentHistory.subscription)
    var paymentHistory: [PaymentHistory]

    init(
        name: String,
        icon: String,
        amount: Decimal,
        currencyCode: String,
        billingCycle: BillingCycle,
        startDate: Date,
        nextDueDate: Date,
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil,
        status: SubscriptionStatus = .active,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.amount = amount
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.nextDueDate = nextDueDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.status = status
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.paymentHistory = []
    }
}
```

- [ ] **Step 4: Create PaymentHistory model**

```swift
// Sotto/Sotto/Models/PaymentHistory.swift
import Foundation
import SwiftData

@Model
final class PaymentHistory {
    @Attribute(.unique) var id: UUID
    var subscription: Subscription?
    var paidDate: Date
    var amount: Decimal
    var currencyCode: String

    init(subscription: Subscription, paidDate: Date, amount: Decimal, currencyCode: String) {
        self.id = UUID()
        self.subscription = subscription
        self.paidDate = paidDate
        self.amount = amount
        self.currencyCode = currencyCode
    }
}
```

- [ ] **Step 5: Create ExchangeRate model**

```swift
// Sotto/Sotto/Models/ExchangeRate.swift
import Foundation
import SwiftData

@Model
final class ExchangeRate {
    @Attribute(.unique) var baseCurrency: String
    var rates: [String: Double]
    var lastUpdated: Date

    init(baseCurrency: String, rates: [String: Double]) {
        self.baseCurrency = baseCurrency
        self.rates = rates
        self.lastUpdated = Date()
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 24 * 60 * 60
    }
}
```

- [ ] **Step 6: Regenerate project and verify build**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add . && git commit -m "feat: add SwiftData models for Subscription, Category, PaymentMethod, PaymentHistory, ExchangeRate"
```

---

## Task 3: Services — BillingCycleCalculator and CurrencyService

**Files:**
- Create: `Sotto/Sotto/Services/BillingCycleCalculator.swift`
- Create: `Sotto/Sotto/Services/CurrencyService.swift`
- Create: `Sotto/Sotto/Extensions/Color+Hex.swift`
- Create: `Sotto/SottoTests/BillingCycleCalculatorTests.swift`
- Create: `Sotto/SottoTests/CurrencyServiceTests.swift`

- [ ] **Step 1: Write BillingCycleCalculator tests**

```swift
// Sotto/SottoTests/BillingCycleCalculatorTests.swift
import Testing
import Foundation
@testable import Sotto

@Suite("BillingCycleCalculator Tests")
struct BillingCycleCalculatorTests {
    let calendar = Calendar.current

    @Test func weeklyAdvancesBySevenDays() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .weekly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 8))!
        #expect(next == expected)
    }

    @Test func monthlyAdvancesByOneMonth() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .monthly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        #expect(next == expected)
    }

    @Test func quarterlyAdvancesByThreeMonths() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .quarterly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        #expect(next == expected)
    }

    @Test func yearlyAdvancesByOneYear() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .yearly)
        let expected = calendar.date(from: DateComponents(year: 2027, month: 6, day: 15))!
        #expect(next == expected)
    }

    @Test func monthlyAmountForWeekly() {
        let amount: Decimal = 10
        let monthly = BillingCycleCalculator.monthlyEquivalent(amount: amount, cycle: .weekly)
        // 10 * 52 / 12 ≈ 43.33
        #expect(monthly > 43 && monthly < 44)
    }

    @Test func monthlyAmountForYearly() {
        let amount: Decimal = 120
        let monthly = BillingCycleCalculator.monthlyEquivalent(amount: amount, cycle: .yearly)
        #expect(monthly == 10)
    }
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd Sotto && xcodegen generate
xcodebuild test -project Sotto.xcodeproj -scheme SottoTests -destination 'platform=macOS'
```

Expected: Compile error — `BillingCycleCalculator` not defined.

- [ ] **Step 3: Implement BillingCycleCalculator**

```swift
// Sotto/Sotto/Services/BillingCycleCalculator.swift
import Foundation

enum BillingCycleCalculator {
    static func nextDueDate(from date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)!
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)!
        }
    }

    static func monthlyEquivalent(amount: Decimal, cycle: BillingCycle) -> Decimal {
        switch cycle {
        case .weekly:
            return amount * 52 / 12
        case .monthly:
            return amount
        case .quarterly:
            return amount / 3
        case .yearly:
            return amount / 12
        }
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
cd Sotto && xcodegen generate
xcodebuild test -project Sotto.xcodeproj -scheme SottoTests -destination 'platform=macOS'
```

Expected: All 6 tests pass.

- [ ] **Step 5: Implement CurrencyService**

```swift
// Sotto/Sotto/Services/CurrencyService.swift
import Foundation
import SwiftData

@Observable
final class CurrencyService {
    private let modelContext: ModelContext
    private(set) var isLoading = false
    private(set) var lastError: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func convert(amount: Decimal, from sourceCurrency: String, to targetCurrency: String) async -> Decimal {
        if sourceCurrency == targetCurrency { return amount }
        guard let rate = await getRate(from: sourceCurrency, to: targetCurrency) else {
            return amount
        }
        return amount * Decimal(rate)
    }

    func refreshRatesIfNeeded(baseCurrency: String) async {
        let cached = fetchCachedRate(baseCurrency: baseCurrency)
        if let cached, !cached.isStale {
            return
        }
        await fetchRates(baseCurrency: baseCurrency)
    }

    private func getRate(from source: String, to target: String) async -> Double? {
        // Try cached rates for source currency
        if let cached = fetchCachedRate(baseCurrency: source), let rate = cached.rates[target] {
            return rate
        }
        // Fetch fresh rates
        await fetchRates(baseCurrency: source)
        return fetchCachedRate(baseCurrency: source)?.rates[target]
    }

    private func fetchCachedRate(baseCurrency: String) -> ExchangeRate? {
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { $0.baseCurrency == baseCurrency }
        )
        return try? modelContext.fetch(descriptor).first
    }

    @MainActor
    private func fetchRates(baseCurrency: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://api.frankfurter.app/latest?from=\(baseCurrency)") else {
            lastError = "Invalid currency code"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)

            // Update or create cached rate
            if let existing = fetchCachedRate(baseCurrency: baseCurrency) {
                existing.rates = response.rates
                existing.lastUpdated = Date()
            } else {
                let rate = ExchangeRate(baseCurrency: baseCurrency, rates: response.rates)
                modelContext.insert(rate)
            }
            try modelContext.save()
        } catch {
            lastError = "Failed to fetch rates: \(error.localizedDescription)"
        }
    }
}

private struct FrankfurterResponse: Decodable {
    let rates: [String: Double]
}
```

- [ ] **Step 6: Create Color+Hex extension**

```swift
// Sotto/Sotto/Extensions/Color+Hex.swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 7: Regenerate, build, and run tests**

```bash
cd Sotto && xcodegen generate
xcodebuild test -project Sotto.xcodeproj -scheme SottoTests -destination 'platform=macOS'
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add . && git commit -m "feat: add BillingCycleCalculator, CurrencyService, and Color+Hex extension"
```

---

## Task 4: Sidebar and Navigation Shell

**Files:**
- Create: `Sotto/Sotto/Views/Sidebar/SidebarView.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create SidebarView**

```swift
// Sotto/Sotto/Views/Sidebar/SidebarView.swift
import SwiftUI
import SwiftData

enum SidebarDestination: String, CaseIterable, Identifiable {
    case dashboard
    case subscriptions
    case calendar
    case categories
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: "Dashboard"
        case .subscriptions: "All Subscriptions"
        case .calendar: "Calendar"
        case .categories: "Categories"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .subscriptions: "list.bullet"
        case .calendar: "calendar"
        case .categories: "tag"
        case .settings: "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarDestination?
    @Query(filter: #Predicate<Subscription> { $0.status == .active })
    private var activeSubscriptions: [Subscription]

    private var urgentCount: Int {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        return activeSubscriptions.filter { $0.nextDueDate <= threeDaysFromNow }.count
    }

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            total + BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section("Navigation") {
                ForEach(SidebarDestination.allCases) { dest in
                    Label(dest.label, systemImage: dest.icon)
                        .tag(dest)
                        .badge(dest == .subscriptions ? urgentCount : 0)
                }
            }

            Section("Quick Stats") {
                LabeledContent("Monthly Total") {
                    Text(monthlyTotal, format: .currency(code: "USD"))
                        .font(.headline)
                }
                LabeledContent("Due Soon") {
                    Text("\(urgentCount)")
                        .font(.headline)
                        .foregroundStyle(urgentCount > 0 ? .red : .secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
```

Note: The `monthlyTotal` here shows amounts in original currencies summed naively. Currency conversion will be integrated in a later task when SettingsView provides the user's base currency.

- [ ] **Step 2: Update ContentView with NavigationSplitView**

```swift
// Sotto/Sotto/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedSubscription: Subscription?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            switch selectedDestination {
            case .dashboard:
                Text("Dashboard — coming soon")
            case .subscriptions:
                Text("Subscriptions — coming soon")
            case .calendar:
                Text("Calendar — coming soon")
            case .categories:
                Text("Categories — coming soon")
            case .settings:
                Text("Settings — coming soon")
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .inspector(isPresented: .constant(selectedSubscription != nil)) {
            if let subscription = selectedSubscription {
                Text("Inspector for \(subscription.name)")
            }
        }
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add . && git commit -m "feat: add sidebar navigation with NavigationSplitView shell"
```

---

## Task 5: Add Subscription Sheet and Category Seeding

**Files:**
- Create: `Sotto/Sotto/Views/Components/IconPicker.swift`
- Create: `Sotto/Sotto/Views/Components/CurrencyPicker.swift`
- Create: `Sotto/Sotto/Views/Subscriptions/AddSubscriptionSheet.swift`
- Modify: `Sotto/Sotto/App/SottoApp.swift` (add category seeding)

- [ ] **Step 1: Create IconPicker**

```swift
// Sotto/Sotto/Views/Components/IconPicker.swift
import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    private let symbols = [
        "play.tv", "film", "music.note", "headphones",
        "laptopcomputer", "desktopcomputer", "keyboard", "printer",
        "cloud", "externaldrive", "server.rack",
        "gamecontroller", "puzzlepiece",
        "newspaper", "book", "graduationcap",
        "bolt", "lightbulb", "wifi", "phone",
        "heart", "figure.run", "dumbbell",
        "cart", "bag", "creditcard",
        "house", "car", "airplane",
        "envelope", "bell", "lock.shield",
        "paintbrush", "camera", "wand.and.stars",
        "ellipsis.circle"
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose an Icon")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 8), spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                        dismiss()
                    } label: {
                        Image(systemName: symbol)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
```

- [ ] **Step 2: Create CurrencyPicker**

```swift
// Sotto/Sotto/Views/Components/CurrencyPicker.swift
import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: String

    static let currencies: [(code: String, name: String)] = [
        ("USD", "US Dollar"),
        ("EUR", "Euro"),
        ("GBP", "British Pound"),
        ("JPY", "Japanese Yen"),
        ("CNY", "Chinese Yuan"),
        ("CAD", "Canadian Dollar"),
        ("AUD", "Australian Dollar"),
        ("CHF", "Swiss Franc"),
        ("HKD", "Hong Kong Dollar"),
        ("SGD", "Singapore Dollar"),
        ("SEK", "Swedish Krona"),
        ("KRW", "South Korean Won"),
        ("NOK", "Norwegian Krone"),
        ("NZD", "New Zealand Dollar"),
        ("INR", "Indian Rupee"),
        ("MXN", "Mexican Peso"),
        ("TWD", "Taiwan Dollar"),
        ("BRL", "Brazilian Real"),
        ("DKK", "Danish Krone"),
        ("PLN", "Polish Zloty"),
        ("THB", "Thai Baht"),
        ("TRY", "Turkish Lira")
    ]

    var body: some View {
        Picker("Currency", selection: $selectedCurrency) {
            ForEach(Self.currencies, id: \.code) { currency in
                Text("\(currency.code) — \(currency.name)").tag(currency.code)
            }
        }
    }
}
```

- [ ] **Step 3: Create AddSubscriptionSheet**

```swift
// Sotto/Sotto/Views/Subscriptions/AddSubscriptionSheet.swift
import SwiftUI
import SwiftData

struct AddSubscriptionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @Query private var paymentMethods: [PaymentMethod]

    var existingSubscription: Subscription?

    @State private var name = ""
    @State private var icon = "ellipsis.circle"
    @State private var amount = ""
    @State private var currencyCode = "USD"
    @State private var billingCycle = BillingCycle.monthly
    @State private var startDate = Date()
    @State private var selectedCategory: Category?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var notes = ""
    @State private var showIconPicker = false

    private var isValid: Bool {
        !name.isEmpty && Decimal(string: amount) != nil && selectedCategory != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(existingSubscription == nil ? "New Subscription" : "Edit Subscription")
                    .font(.headline)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()

            Divider()

            Form {
                Section("Details") {
                    HStack {
                        Button {
                            showIconPicker = true
                        } label: {
                            Image(systemName: icon)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showIconPicker) {
                            IconPicker(selectedIcon: $icon)
                        }

                        TextField("Subscription Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        CurrencyPicker(selectedCurrency: $currencyCode)
                    }

                    Picker("Billing Cycle", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.displayName).tag(cycle)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Organization") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category as Category?)
                        }
                    }

                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        Text("None").tag(nil as PaymentMethod?)
                        ForEach(paymentMethods) { method in
                            Text(method.name).tag(method as PaymentMethod?)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 480, height: 520)
        .onAppear { populateForEdit() }
    }

    private func populateForEdit() {
        guard let sub = existingSubscription else { return }
        name = sub.name
        icon = sub.icon
        amount = "\(sub.amount)"
        currencyCode = sub.currencyCode
        billingCycle = sub.billingCycle
        startDate = sub.startDate
        selectedCategory = sub.category
        selectedPaymentMethod = sub.paymentMethod
        notes = sub.notes ?? ""
    }

    private func save() {
        guard let decimalAmount = Decimal(string: amount) else { return }
        let nextDue = BillingCycleCalculator.nextDueDate(from: startDate, cycle: billingCycle)

        if let existing = existingSubscription {
            existing.name = name
            existing.icon = icon
            existing.amount = decimalAmount
            existing.currencyCode = currencyCode
            existing.billingCycle = billingCycle
            existing.startDate = startDate
            existing.nextDueDate = nextDue
            existing.category = selectedCategory
            existing.paymentMethod = selectedPaymentMethod
            existing.notes = notes.isEmpty ? nil : notes
            existing.updatedAt = Date()
        } else {
            let subscription = Subscription(
                name: name,
                icon: icon,
                amount: decimalAmount,
                currencyCode: currencyCode,
                billingCycle: billingCycle,
                startDate: startDate,
                nextDueDate: nextDue,
                category: selectedCategory,
                paymentMethod: selectedPaymentMethod,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(subscription)
        }

        dismiss()
    }
}
```

- [ ] **Step 4: Add category seeding to SottoApp**

```swift
// Sotto/Sotto/App/SottoApp.swift
import SwiftUI
import SwiftData

@main
struct SottoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { seedDefaultCategories() }
        }
        .modelContainer(for: [
            Subscription.self,
            Category.self,
            PaymentMethod.self,
            PaymentHistory.self,
            ExchangeRate.self
        ])
    }

    @MainActor
    private func seedDefaultCategories() {
        guard let container = try? ModelContainer(for: Category.self) else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for item in Category.defaults {
            let category = Category(name: item.name, colorHex: item.colorHex, icon: item.icon)
            context.insert(category)
        }
    }
}
```

Wait — using two separate ModelContainers would cause issues. Let me fix the approach:

```swift
// Sotto/Sotto/App/SottoApp.swift
import SwiftUI
import SwiftData

@main
struct SottoApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for:
                Subscription.self,
                Category.self,
                PaymentMethod.self,
                PaymentHistory.self,
                ExchangeRate.self
            )
            SottoApp.seedDefaultCategories(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private static func seedDefaultCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for item in Category.defaults {
            let category = Category(name: item.name, colorHex: item.colorHex, icon: item.icon)
            context.insert(category)
        }
    }
}
```

- [ ] **Step 5: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add . && git commit -m "feat: add subscription form, icon picker, currency picker, and category seeding"
```

---

## Task 6: Subscription List View

**Files:**
- Create: `Sotto/Sotto/Views/Subscriptions/SubscriptionRow.swift`
- Create: `Sotto/Sotto/Views/Subscriptions/SubscriptionListView.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create SubscriptionRow**

```swift
// Sotto/Sotto/Views/Subscriptions/SubscriptionRow.swift
import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription

    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextDueDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.icon)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(subscription.category.map { Color(hex: $0.colorHex).opacity(0.2) } ?? Color.gray.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(subscription.billingCycle.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let category = subscription.category {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                    .font(.body)
                    .fontWeight(.medium)
                if subscription.status == .active {
                    Text(daysUntilDue <= 0 ? "Due today" : "in \(daysUntilDue) days")
                        .font(.caption)
                        .foregroundStyle(daysUntilDue <= 3 ? .red : .secondary)
                } else {
                    Text(subscription.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Create SubscriptionListView**

```swift
// Sotto/Sotto/Views/Subscriptions/SubscriptionListView.swift
import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]
    @Query private var categories: [Category]
    @Binding var selectedSubscription: Subscription?
    @State private var searchText = ""
    @State private var statusFilter: SubscriptionStatus? = .active
    @State private var categoryFilter: Category?
    @State private var showAddSheet = false

    private var filteredSubscriptions: [Subscription] {
        subscriptions.filter { sub in
            let matchesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil || sub.status == statusFilter
            let matchesCategory = categoryFilter == nil || sub.category?.id == categoryFilter?.id
            return matchesSearch && matchesStatus && matchesCategory
        }
    }

    var body: some View {
        List(filteredSubscriptions, selection: $selectedSubscription) { subscription in
            SubscriptionRow(subscription: subscription)
                .tag(subscription)
                .contextMenu {
                    if subscription.status == .active {
                        Button("Pause") { subscription.status = .paused; subscription.updatedAt = Date() }
                    }
                    if subscription.status == .paused {
                        Button("Resume") { subscription.status = .active; subscription.updatedAt = Date() }
                    }
                    if subscription.status != .cancelled {
                        Button("Cancel Subscription") { subscription.status = .cancelled; subscription.updatedAt = Date() }
                    }
                    Divider()
                    Button("Delete", role: .destructive) { deleteSubscription(subscription) }
                }
        }
        .searchable(text: $searchText, prompt: "Search subscriptions")
        .toolbar {
            ToolbarItem {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Subscription", systemImage: "plus")
                }
            }
            ToolbarItem {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag(nil as SubscriptionStatus?)
                    ForEach(SubscriptionStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as SubscriptionStatus?)
                    }
                }
            }
            ToolbarItem {
                Picker("Category", selection: $categoryFilter) {
                    Text("All Categories").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
        }
        .navigationTitle("All Subscriptions")
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteSubscription(_ subscription: Subscription) {
        if selectedSubscription?.id == subscription.id {
            selectedSubscription = nil
        }
        modelContext.delete(subscription)
    }
}
```

- [ ] **Step 3: Wire into ContentView**

Replace the detail switch in ContentView:

```swift
// Sotto/Sotto/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedSubscription: Subscription?
    @State private var showInspector = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            switch selectedDestination {
            case .dashboard:
                Text("Dashboard — coming soon")
            case .subscriptions:
                SubscriptionListView(selectedSubscription: $selectedSubscription)
            case .calendar:
                Text("Calendar — coming soon")
            case .categories:
                Text("Categories — coming soon")
            case .settings:
                Text("Settings — coming soon")
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .inspector(isPresented: $showInspector) {
            if let subscription = selectedSubscription {
                InspectorPane(subscription: subscription)
                    .inspectorColumnWidth(min: 250, ideal: 300, max: 350)
            }
        }
        .onChange(of: selectedSubscription) { _, newValue in
            showInspector = newValue != nil
        }
    }
}
```

- [ ] **Step 4: Create a placeholder InspectorPane**

```swift
// Sotto/Sotto/Views/Components/InspectorPane.swift
import SwiftUI

struct InspectorPane: View {
    let subscription: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(subscription.name)
                .font(.title2)
                .fontWeight(.bold)
            Text("Inspector details — coming in Task 8")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
```

- [ ] **Step 5: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add . && git commit -m "feat: add subscription list with search, filters, and context menus"
```

---

## Task 7: Dashboard View

**Files:**
- Create: `Sotto/Sotto/Views/Dashboard/DashboardView.swift`
- Create: `Sotto/Sotto/Views/Dashboard/SpendingCard.swift`
- Create: `Sotto/Sotto/Views/Dashboard/CategoryChart.swift`
- Create: `Sotto/Sotto/Views/Dashboard/UpcomingRenewalsCard.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create SpendingCard**

```swift
// Sotto/Sotto/Views/Dashboard/SpendingCard.swift
import SwiftUI
import SwiftData

struct SpendingCard: View {
    @Query(filter: #Predicate<Subscription> { $0.status == .active })
    private var activeSubscriptions: [Subscription]

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            total + BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
        }
    }

    private var yearlyTotal: Decimal {
        monthlyTotal * 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Spending", systemImage: "creditcard")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(monthlyTotal, format: .currency(code: "USD"))
                .font(.system(size: 36, weight: .bold, design: .rounded))

            HStack {
                Text("Yearly estimate:")
                    .foregroundStyle(.secondary)
                Text(yearlyTotal, format: .currency(code: "USD"))
                    .fontWeight(.medium)
            }
            .font(.subheadline)

            Text("\(activeSubscriptions.count) active subscriptions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
```

- [ ] **Step 2: Create CategoryChart**

```swift
// Sotto/Sotto/Views/Dashboard/CategoryChart.swift
import SwiftUI
import SwiftData
import Charts

struct CategoryChart: View {
    @Query(filter: #Predicate<Subscription> { $0.status == .active })
    private var activeSubscriptions: [Subscription]

    private var categoryBreakdown: [(name: String, colorHex: String, amount: Decimal)] {
        var map: [String: (colorHex: String, amount: Decimal)] = [:]
        for sub in activeSubscriptions {
            let catName = sub.category?.name ?? "Uncategorized"
            let catColor = sub.category?.colorHex ?? "#B0B0B0"
            let monthly = BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
            let existing = map[catName] ?? (colorHex: catColor, amount: 0)
            map[catName] = (colorHex: catColor, amount: existing.amount + monthly)
        }
        return map.map { (name: $0.key, colorHex: $0.value.colorHex, amount: $0.value.amount) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("By Category", systemImage: "chart.pie")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if categoryBreakdown.isEmpty {
                Text("No active subscriptions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart(categoryBreakdown, id: \.name) { item in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: item.amount).doubleValue),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                    .annotation(position: .overlay) {
                        Text(item.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                .frame(height: 180)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(categoryBreakdown, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(Color(hex: item.colorHex))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text(item.amount, format: .currency(code: "USD"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
```

- [ ] **Step 3: Create UpcomingRenewalsCard**

```swift
// Sotto/Sotto/Views/Dashboard/UpcomingRenewalsCard.swift
import SwiftUI
import SwiftData

struct UpcomingRenewalsCard: View {
    @Query(
        filter: #Predicate<Subscription> { $0.status == .active },
        sort: \Subscription.nextDueDate
    )
    private var activeSubscriptions: [Subscription]

    private var upcoming: [Subscription] {
        Array(activeSubscriptions.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Renewals", systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if upcoming.isEmpty {
                Text("No upcoming renewals")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(upcoming) { sub in
                    HStack {
                        Image(systemName: sub.icon)
                            .frame(width: 24)
                        Text(sub.name)
                            .lineLimit(1)
                        Spacer()
                        Text(sub.amount, format: .currency(code: sub.currencyCode))
                            .font(.subheadline)
                        daysUntilBadge(for: sub)
                    }
                    if sub.id != upcoming.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func daysUntilBadge(for subscription: Subscription) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: subscription.nextDueDate)).day ?? 0
        let text = days <= 0 ? "Today" : "\(days)d"
        let isUrgent = days <= 3
        return Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(isUrgent ? Color.red.opacity(0.15) : Color.secondary.opacity(0.1))
            )
            .foregroundStyle(isUrgent ? .red : .secondary)
    }
}
```

- [ ] **Step 4: Create DashboardView**

```swift
// Sotto/Sotto/Views/Dashboard/DashboardView.swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(
        filter: #Predicate<PaymentHistory> { _ in true },
        sort: \PaymentHistory.paidDate,
        order: .reverse
    )
    private var recentPayments: [PaymentHistory]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top row: spending + chart
                HStack(alignment: .top, spacing: 16) {
                    SpendingCard()
                    CategoryChart()
                }

                // Bottom row: upcoming + recent
                HStack(alignment: .top, spacing: 16) {
                    UpcomingRenewalsCard()
                    recentActivityCard
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let recent = Array(recentPayments.prefix(5))
            if recent.isEmpty {
                Text("No recorded payments yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(recent) { payment in
                    HStack {
                        Text(payment.subscription?.name ?? "Unknown")
                            .lineLimit(1)
                        Spacer()
                        Text(payment.amount, format: .currency(code: payment.currencyCode))
                            .font(.subheadline)
                        Text(payment.paidDate, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if payment.id != recent.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
```

- [ ] **Step 5: Wire DashboardView into ContentView**

In `ContentView.swift`, replace `Text("Dashboard — coming soon")` with:

```swift
case .dashboard:
    DashboardView()
```

- [ ] **Step 6: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add . && git commit -m "feat: add dashboard with spending card, category chart, upcoming renewals, and recent activity"
```

---

## Task 8: Inspector Pane with Payment Recording

**Files:**
- Modify: `Sotto/Sotto/Views/Components/InspectorPane.swift`

- [ ] **Step 1: Implement full InspectorPane**

```swift
// Sotto/Sotto/Views/Components/InspectorPane.swift
import SwiftUI
import SwiftData

struct InspectorPane: View {
    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false

    private var daysUntilDue: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: subscription.nextDueDate)
        ).day ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: subscription.icon)
                        .font(.largeTitle)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(subscription.category.map { Color(hex: $0.colorHex).opacity(0.2) } ?? Color.gray.opacity(0.1))
                        )
                    VStack(alignment: .leading) {
                        Text(subscription.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let category = subscription.category {
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Amount & Cycle
                LabeledContent("Amount") {
                    Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                        .fontWeight(.semibold)
                }
                LabeledContent("Billing Cycle") {
                    Text(subscription.billingCycle.displayName)
                }
                LabeledContent("Status") {
                    Text(subscription.status.displayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(statusColor.opacity(0.15)))
                        .foregroundStyle(statusColor)
                }
                LabeledContent("Next Due") {
                    VStack(alignment: .trailing) {
                        Text(subscription.nextDueDate, format: .dateTime.month(.abbreviated).day().year())
                        if subscription.status == .active {
                            Text(daysUntilDue <= 0 ? "Due today" : "in \(daysUntilDue) days")
                                .font(.caption)
                                .foregroundStyle(daysUntilDue <= 3 ? .red : .secondary)
                        }
                    }
                }
                if let method = subscription.paymentMethod {
                    LabeledContent("Payment Method") {
                        Text(method.name)
                    }
                }
                if let notes = subscription.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.body)
                    }
                }

                Divider()

                // Quick Actions
                VStack(spacing: 8) {
                    if subscription.status == .active {
                        Button {
                            markAsPaid()
                        } label: {
                            Label("Mark as Paid", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 8) {
                        if subscription.status == .active {
                            Button {
                                subscription.status = .paused
                                subscription.updatedAt = Date()
                            } label: {
                                Label("Pause", systemImage: "pause.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        if subscription.status == .paused {
                            Button {
                                subscription.status = .active
                                subscription.updatedAt = Date()
                            } label: {
                                Label("Resume", systemImage: "play.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                    }

                    if subscription.status != .cancelled {
                        Button(role: .destructive) {
                            subscription.status = .cancelled
                            subscription.updatedAt = Date()
                        } label: {
                            Label("Cancel Subscription", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                Divider()

                // Payment History
                paymentHistorySection
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            AddSubscriptionSheet(existingSubscription: subscription)
        }
    }

    private var statusColor: Color {
        switch subscription.status {
        case .active: .green
        case .paused: .orange
        case .cancelled: .red
        }
    }

    private func markAsPaid() {
        let payment = PaymentHistory(
            subscription: subscription,
            paidDate: Date(),
            amount: subscription.amount,
            currencyCode: subscription.currencyCode
        )
        modelContext.insert(payment)
        subscription.nextDueDate = BillingCycleCalculator.nextDueDate(
            from: subscription.nextDueDate,
            cycle: subscription.billingCycle
        )
        subscription.updatedAt = Date()
    }

    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment History")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let sorted = subscription.paymentHistory.sorted { $0.paidDate > $1.paidDate }
            if sorted.isEmpty {
                Text("No payments recorded")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sorted) { payment in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(payment.paidDate, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption)
                        Spacer()
                        Text(payment.amount, format: .currency(code: payment.currencyCode))
                            .font(.caption)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: add inspector pane with subscription details, quick actions, and payment recording"
```

---

## Task 9: Calendar View

**Files:**
- Create: `Sotto/Sotto/Views/Calendar/CalendarView.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create CalendarView**

```swift
// Sotto/Sotto/Views/Calendar/CalendarView.swift
import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(filter: #Predicate<Subscription> { $0.status == .active })
    private var activeSubscriptions: [Subscription]
    @Binding var selectedSubscription: Subscription?
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [Date] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return range.compactMap { day in
            calendar.date(from: DateComponents(year: components.year, month: components.month, day: day))
        }
    }

    private var leadingEmptyDays: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    private func subscriptions(on date: Date) -> [Subscription] {
        let startOfDay = calendar.startOfDay(for: date)
        return activeSubscriptions.filter { calendar.startOfDay(for: $0.nextDueDate) == startOfDay }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text(monthTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(minWidth: 200)

                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)

                Button("Today") {
                    displayedMonth = Date()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear.frame(height: 72)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    let subs = subscriptions(on: date)
                    let isToday = calendar.isDateInToday(date)

                    VStack(spacing: 2) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.subheadline)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(isToday ? .white : .primary)
                            .frame(width: 24, height: 24)
                            .background(isToday ? Circle().fill(Color.accentColor) : nil)

                        if !subs.isEmpty {
                            VStack(spacing: 1) {
                                ForEach(subs.prefix(2)) { sub in
                                    Text(sub.name)
                                        .font(.system(size: 9))
                                        .lineLimit(1)
                                        .padding(.horizontal, 3)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(sub.category.map { Color(hex: $0.colorHex).opacity(0.3) } ?? Color.gray.opacity(0.15))
                                        )
                                }
                                if subs.count > 2 {
                                    Text("+\(subs.count - 2)")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 72)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(!subs.isEmpty ? Color.accentColor.opacity(0.05) : Color.clear)
                    )
                    .onTapGesture {
                        if let first = subs.first {
                            selectedSubscription = first
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Calendar")
    }
}
```

- [ ] **Step 2: Wire CalendarView into ContentView**

In `ContentView.swift`, replace `Text("Calendar — coming soon")` with:

```swift
case .calendar:
    CalendarView(selectedSubscription: $selectedSubscription)
```

- [ ] **Step 3: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add . && git commit -m "feat: add calendar view with month navigation and renewal markers"
```

---

## Task 10: Categories Management View

**Files:**
- Create: `Sotto/Sotto/Views/Categories/CategoriesView.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create CategoriesView**

```swift
// Sotto/Sotto/Views/Categories/CategoriesView.swift
import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCategory = false
    @State private var editingCategory: Category?

    // Add form state
    @State private var newName = ""
    @State private var newColorHex = "#4ECDC4"
    @State private var newIcon = "tag"

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .frame(width: 32)

                    VStack(alignment: .leading) {
                        Text(category.name)
                            .fontWeight(.medium)
                        Text("\(category.subscriptions.count) subscriptions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    let total = category.subscriptions
                        .filter { $0.status == .active }
                        .reduce(Decimal.zero) { $0 + BillingCycleCalculator.monthlyEquivalent(amount: $1.amount, cycle: $1.billingCycle) }

                    if total > 0 {
                        Text(total, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("/mo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 12, height: 12)
                }
                .contextMenu {
                    Button("Edit") { editingCategory = category }
                    Button("Delete", role: .destructive) { modelContext.delete(category) }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            Button {
                showAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAddCategory) {
            categoryForm(editing: nil)
        }
        .sheet(item: $editingCategory) { category in
            categoryForm(editing: category)
        }
    }

    private func categoryForm(editing: Category?) -> some View {
        let isEditing = editing != nil

        return VStack(spacing: 16) {
            Text(isEditing ? "Edit Category" : "New Category")
                .font(.headline)

            Form {
                TextField("Name", text: $newName)
                TextField("Color (hex)", text: $newColorHex)
                HStack {
                    Text("Preview:")
                    Circle().fill(Color(hex: newColorHex)).frame(width: 20, height: 20)
                }
                TextField("SF Symbol", text: $newIcon)
                HStack {
                    Text("Preview:")
                    Image(systemName: newIcon)
                        .font(.title2)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    showAddCategory = false
                    editingCategory = nil
                    resetForm()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    if let category = editing {
                        category.name = newName
                        category.colorHex = newColorHex
                        category.icon = newIcon
                    } else {
                        let category = Category(name: newName, colorHex: newColorHex, icon: newIcon)
                        modelContext.insert(category)
                    }
                    showAddCategory = false
                    editingCategory = nil
                    resetForm()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 320)
        .onAppear {
            if let category = editing {
                newName = category.name
                newColorHex = category.colorHex
                newIcon = category.icon
            } else {
                resetForm()
            }
        }
    }

    private func resetForm() {
        newName = ""
        newColorHex = "#4ECDC4"
        newIcon = "tag"
    }
}
```

- [ ] **Step 2: Wire CategoriesView into ContentView**

In `ContentView.swift`, replace `Text("Categories — coming soon")` with:

```swift
case .categories:
    CategoriesView()
```

- [ ] **Step 3: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add . && git commit -m "feat: add categories management view with add/edit/delete"
```

---

## Task 11: Settings View

**Files:**
- Create: `Sotto/Sotto/Views/Settings/SettingsView.swift`
- Modify: `Sotto/Sotto/Views/ContentView.swift`

- [ ] **Step 1: Create SettingsView**

```swift
// Sotto/Sotto/Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @Query private var exchangeRates: [ExchangeRate]
    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshingRates = false

    private var cachedRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    var body: some View {
        Form {
            Section("Currency") {
                CurrencyPicker(selectedCurrency: $baseCurrency)

                if let rate = cachedRate {
                    LabeledContent("Exchange Rates") {
                        VStack(alignment: .trailing) {
                            Text("Last updated: \(rate.lastUpdated, format: .dateTime)")
                                .font(.caption)
                                .foregroundStyle(rate.isStale ? .red : .secondary)
                            if rate.isStale {
                                Text("Rates may be outdated")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Button {
                    Task {
                        isRefreshingRates = true
                        let service = CurrencyService(modelContext: modelContext)
                        await service.refreshRatesIfNeeded(baseCurrency: baseCurrency)
                        isRefreshingRates = false
                    }
                } label: {
                    HStack {
                        Label("Refresh Exchange Rates", systemImage: "arrow.clockwise")
                        if isRefreshingRates {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isRefreshingRates)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                }
                LabeledContent("Platform") {
                    Text("macOS")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
```

- [ ] **Step 2: Wire SettingsView into ContentView**

In `ContentView.swift`, replace `Text("Settings — coming soon")` with:

```swift
case .settings:
    SettingsView()
```

- [ ] **Step 3: Build and verify**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add . && git commit -m "feat: add settings view with base currency selection and exchange rate management"
```

---

## Task 12: Final Integration, Polish, and Full Build Verification

**Files:**
- Modify: Various files for minor fixes identified during integration

- [ ] **Step 1: Ensure all navigation destinations are wired**

Verify `ContentView.swift` has all cases handled and no placeholder text remains.

- [ ] **Step 2: Run full build**

```bash
cd Sotto && xcodegen generate
xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination 'platform=macOS' build
```

Expected: Build succeeds with no errors.

- [ ] **Step 3: Run all tests**

```bash
cd Sotto && xcodebuild test -project Sotto.xcodeproj -scheme SottoTests -destination 'platform=macOS'
```

Expected: All tests pass.

- [ ] **Step 4: Commit final state**

```bash
git add . && git commit -m "feat: complete Sotto v1 — subscription tracker with dashboard, calendar, categories, and settings"
```

---

## Summary

| Task | Description | Dependencies |
|------|-------------|-------------|
| 1 | Project scaffolding (XcodeGen, app entry, assets) | None |
| 2 | SwiftData models (Subscription, Category, PaymentMethod, PaymentHistory, ExchangeRate) | Task 1 |
| 3 | Services (BillingCycleCalculator, CurrencyService, Color+Hex) | Task 2 |
| 4 | Sidebar + NavigationSplitView shell | Task 2, 3 |
| 5 | AddSubscriptionSheet, IconPicker, CurrencyPicker, category seeding | Task 2, 3 |
| 6 | SubscriptionListView with search/filters | Task 4, 5 |
| 7 | Dashboard (SpendingCard, CategoryChart, UpcomingRenewals, RecentActivity) | Task 3, 4 |
| 8 | InspectorPane with payment recording | Task 4, 5 |
| 9 | CalendarView | Task 4 |
| 10 | CategoriesView | Task 2, 4 |
| 11 | SettingsView | Task 3, 4 |
| 12 | Final integration and verification | All |
