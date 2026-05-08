import SwiftUI
import SwiftData

struct CalendarView: View {

    // MARK: - Properties

    @Query private var allSubscriptions: [Subscription]
    @State private var displayedMonth = Date()

    // MARK: - Computed Properties

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
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
        return allSubscriptions.filter {
            calendar.startOfDay(for: $0.nextDueDate) == startOfDay
        }
    }

    // MARK: - Body

    var body: some View {
        #if os(iOS)
        // Single ScrollView so the navigation large title shrinks smoothly on scroll
        // (sibling-VStack-above-ScrollView breaks the iOS title-shrink animation,
        // and safeAreaInset(.top) hides the large title at rest).
        ScrollView {
            VStack(spacing: 0) {
                monthNavBar
                if isCompact {
                    statusLegend
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                weekdayHeader
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear.frame(height: compactRowHeight)
                    }
                    ForEach(daysInMonth, id: \.self) { date in
                        dayCell(date: date, height: compactRowHeight)
                    }
                }
                .padding(.horizontal)
            }
        }
        .safeAreaPadding(.bottom, 64)
        .background(DesignTokens.windowBackground)
        .navigationTitle("Calendar")
        #else
        VStack(spacing: 0) {
            monthNavBar
            weekdayHeader
            Divider()
            GeometryReader { geo in
                let totalRows = CGFloat((leadingEmptyDays + daysInMonth.count + 6) / 7)
                let rowHeight = max(56, geo.size.height / totalRows)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear.frame(height: rowHeight)
                    }
                    ForEach(daysInMonth, id: \.self) { date in
                        dayCell(date: date, height: rowHeight)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(DesignTokens.windowBackground)
        .navigationTitle("Calendar")
        #endif
    }

    private var monthNavBar: some View {
        HStack(spacing: 8) {
            Button {
                if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                    displayedMonth = newMonth
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(monthTitle)
                .font(.title2)
                .fontWeight(.bold)

            Button {
                if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                    displayedMonth = newMonth
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            Spacer()

            if !isCompact {
                statusLegend
            }

            Button("Today") {
                displayedMonth = Date()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private var gridScrollView: some View {
        ScrollView {
            GeometryReader { geo in
                let totalRows = CGFloat((leadingEmptyDays + daysInMonth.count + 6) / 7)
                let macRowHeight = max(56, geo.size.height / totalRows)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear.frame(height: isCompact ? compactRowHeight : macRowHeight)
                    }

                    ForEach(daysInMonth, id: \.self) { date in
                        dayCell(date: date, height: isCompact ? compactRowHeight : macRowHeight)
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: isCompact ? .infinity : nil, alignment: .top)
            }
            .frame(minHeight: isCompact
                   ? CGFloat((leadingEmptyDays + daysInMonth.count + 6) / 7) * compactRowHeight
                   : 0)
        }
        #if os(iOS)
        .safeAreaPadding(.bottom, 64)
        #endif
    }

    /// Fixed row height on iPhone so the grid is taller than the viewport
    /// when needed, letting the navigation large-title shrink on scroll.
    private let compactRowHeight: CGFloat = 116

    // MARK: - Private Views

    private var statusLegend: some View {
        HStack(spacing: 12) {
            ForEach(SubscriptionStatus.allCases, id: \.self) { status in
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.calendarColor)
                        .frame(width: 7, height: 7)
                    Text(status.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dayCell(date: Date, height: CGFloat) -> some View {
        let subs = subscriptions(on: date)
        let isToday = calendar.isDateInToday(date)
        let hasSubscriptions = !subs.isEmpty

        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(isToday ? Circle().fill(Color.accentColor) : nil)

            if hasSubscriptions {
                VStack(spacing: 1) {
                    ForEach(subs.prefix(3)) { sub in
                        subscriptionChip(sub)
                    }
                    if subs.count > 3 {
                        Text("+\(subs.count - 3) more")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(hasSubscriptions ? Color.accentColor.opacity(0.04) : Color.clear)
        )
    }

    private func subscriptionChip(_ sub: Subscription) -> some View {
        let chipColor = sub.status.calendarColor
        return HStack(spacing: 2) {
            Circle()
                .fill(chipColor)
                .frame(width: 5, height: 5)
            Text(sub.name)
                .font(.system(size: 9))
                .lineLimit(1)
                .strikethrough(sub.status == .cancelled, color: chipColor)
                .foregroundStyle(sub.status == .cancelled ? .secondary : .primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(chipColor.opacity(0.18))
        )
    }
}

// MARK: - SubscriptionStatus + Calendar Color

extension SubscriptionStatus {
    var calendarColor: Color {
        switch self {
        case .active:    return .green
        case .paused:    return .orange
        case .cancelled: return .red
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(makePreviewContainer())
}
