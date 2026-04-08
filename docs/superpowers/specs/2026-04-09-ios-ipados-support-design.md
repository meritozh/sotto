# Sotto iOS/iPadOS Support — Design Specification

**Date:** 2026-04-09
**Status:** Approved
**Depends on:** 2026-04-03-sotto-design.md (macOS v1)

---

## Overview

Make Sotto a universal app supporting macOS, iOS, and iPadOS. The app already uses SwiftUI, SwiftData, and SF Symbols — all cross-platform. The primary work is adaptive layout per device and replacing macOS-only APIs.

---

## Platform Layout

| Device | Navigation | Detail Inspector |
|--------|-----------|-----------------|
| iPhone (compact) | TabView with 5 tabs + NavigationStack per tab | Push navigation (full screen) |
| iPad (regular) | NavigationSplitView 2-column (sidebar \| content) | Slide-in overlay panel from right edge |
| macOS | NavigationSplitView 2-column (sidebar \| content) | Slide-in overlay panel from right edge |

iPad and macOS share the same code path. iPhone is the only distinct path.

---

## iPhone Layout

### TabView

Five tabs at the bottom, each wrapping its view in a NavigationStack:

1. Dashboard (icon: `square.grid.2x2`)
2. Subscriptions (icon: `list.bullet`)
3. Calendar (icon: `calendar`)
4. Categories (icon: `tag`)
5. Settings (icon: `gearshape`)

### Subscription Detail

Tapping a subscription in the list or calendar pushes `InspectorPane` as a full-screen view via `NavigationStack` / `navigationDestination`. Standard iOS drill-down pattern.

### Add Subscription

Same `.sheet()` presentation as macOS — works cross-platform without changes.

---

## iPad + macOS Layout

### Two-Column NavigationSplitView

- **Sidebar:** Same `SidebarView` (navigation items + quick stats)
- **Content:** Switches based on sidebar selection (Dashboard, Subscriptions, Calendar, Categories, Settings)

### Slide-In Overlay Panel (Inspector)

- Triggered when a subscription is selected (from list, calendar, or dashboard)
- Implemented as a `ZStack` or `.overlay(alignment: .trailing)` on the content area
- Animated with `.transition(.move(edge: .trailing))` + `withAnimation(.easeInOut)`
- Floats over content (does not resize the content column)
- Fixed width: ~320pt
- Visual treatment: background fill, leading shadow for depth
- Dismiss: close button in panel, click outside panel, or Escape key
- Selecting a different subscription updates the panel content without re-animating

### Why Not Three-Column or HSplitView

- Three-column NavigationSplitView: detail column always visible, wastes space for an infrequent action
- HSplitView: AppKit bridge, no animations, caused Auto Layout constraint crashes with sidebar toggle
- `.inspector()` modifier: AppKit-level column, caused constraint crashes when combined with NavigationSplitView sidebar

---

## Changes Required

### Project Configuration

- Update `project.yml` to make the Sotto target universal (macOS + iOS)
- Add iOS deployment target: 17.0
- Add iOS device families (iPhone + iPad)

### ContentView (Major Rework)

Replace the current single-platform ContentView with adaptive layout:

```
#if os(iOS)
  if horizontalSizeClass == .compact {
    // iPhone: TabView + NavigationStack
  } else {
    // iPad: NavigationSplitView 2-column + overlay panel
  }
#else
  // macOS: NavigationSplitView 2-column + overlay panel
#endif
```

The iPad and macOS paths share the same view code since both use 2-column + overlay.

### New: SubscriptionDetailOverlay

A new component that wraps `InspectorPane` in an animated overlay panel:
- `ZStack(alignment: .trailing)` containing the content view and the panel
- Conditional rendering based on `selectedSubscription != nil`
- `withAnimation` on selection change
- `.transition(.move(edge: .trailing))` on the panel
- Background dimming layer that dismisses on tap
- Shadow on the panel's leading edge

### Platform-Specific API Replacements

| Current (macOS-only) | Replacement |
|----------------------|-------------|
| `Color(nsColor: .windowBackgroundColor)` | `#if os(macOS) Color(nsColor: .windowBackgroundColor) #else Color(.systemGroupedBackground) #endif` |
| `HSplitView` in ContentView | Remove entirely — replaced by overlay panel |
| `.frame(minWidth: 800, minHeight: 500)` | `#if os(macOS)` guard only |

### Views That Work Cross-Platform Without Changes

- All SwiftData models
- BillingCycleCalculator, CurrencyService
- SidebarView (used on iPad/macOS, not iPhone)
- DashboardView, SpendingCard, CategoryChart, UpcomingRenewalsCard
- SubscriptionListView, SubscriptionRow
- AddSubscriptionSheet
- CalendarView (GeometryReader already adapts)
- CategoriesView
- SettingsView
- InspectorPane
- IconPicker, CurrencyPicker
- Color+Hex extension

### Minor Adjustments

- InspectorPane: add a close button (X) in the header for overlay dismiss — currently relies on macOS implicit inspector close
- CalendarView: may need `@Environment(\.horizontalSizeClass)` for smaller font on iPhone compact, but GeometryReader should handle most sizing

---

## Scope Boundaries

### In Scope
- Universal app target (macOS + iOS + iPadOS)
- Adaptive layout: TabView (iPhone), 2-column + overlay (iPad/macOS)
- Replace macOS-only APIs with cross-platform equivalents
- Slide-in overlay panel for subscription detail

### Out of Scope
- Widgets (iOS/macOS)
- Apple Watch support
- System push notifications
- CloudKit entitlements (already deferred in v1 spec)
- Any new features — this is strictly a platform expansion
