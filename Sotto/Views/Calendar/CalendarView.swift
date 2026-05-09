import SwiftUI
import SwiftData

struct CalendarView: View {

    // MARK: - Properties

    @Query private var allSubscriptions: [Subscription]
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?

    // MARK: - Computed Properties

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

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
            calendar.startOfDay(for: $0.currentDueDate) == startOfDay
        }
    }

    /// The day to surface in the detail list. Defaults to today on first launch and
    /// whenever the user jumps months without an explicit selection.
    private var detailDate: Date {
        selectedDate ?? Date()
    }

    // MARK: - Body

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    // MARK: - iOS Body (Apple Calendar pattern: compact grid + day detail below)

    #if os(iOS)
    private var iosBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                monthNavBar
                weekdayHeader
                    .padding(.bottom, 6)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                    spacing: 0
                ) {
                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear.frame(height: compactRowHeight)
                    }
                    ForEach(daysInMonth, id: \.self) { date in
                        compactDayCell(date: date)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDate = date
                            }
                    }
                }
                .padding(.horizontal, 8)

                Rectangle()
                    .fill(DesignTokens.contentDivider)
                    .frame(height: 0.5)
                    .padding(.top, 12)
                    .padding(.horizontal)

                dayDetailSection
                    .padding(.top, 14)
                    .padding(.horizontal)
            }
        }
        .safeAreaPadding(.bottom, 64)
        .background(DesignTokens.windowBackground)
        .navigationTitle("Calendar")
        .onAppear {
            if selectedDate == nil { selectedDate = Date() }
        }
    }
    #endif

    // MARK: - macOS Body (macOS Calendar pattern: cells with inline event bars)

    private var macBody: some View {
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
                        macDayCell(date: date, height: rowHeight)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(DesignTokens.windowBackground)
        .navigationTitle("Calendar")
    }

    // MARK: - Month Navigation Bar

    private var monthNavBar: some View {
        HStack(spacing: 8) {
            Button {
                stepMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(monthTitle)
                .font(.title3)
                .fontWeight(.semibold)

            Button {
                stepMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            #if os(macOS)
            statusLegend
            #endif

            Button("Today") {
                displayedMonth = Date()
                selectedDate = Date()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func stepMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.label3)
                    .textCase(.uppercase)
                    .kerning(0.4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    /// Reorder weekday symbols so the first column matches `Calendar.current.firstWeekday`.
    private var orderedWeekdaySymbols: [String] {
        let firstIndex = calendar.firstWeekday - 1
        return Array(weekdaySymbols[firstIndex...] + weekdaySymbols[..<firstIndex])
    }

    // MARK: - Status Legend (macOS only, redundant on compact)

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

    // MARK: - iOS Compact Day Cell

    /// Compact 56pt cell mirroring Apple Calendar: centered date, today as a red
    /// filled circle, up to 4 colored dots beneath for the day's subscriptions,
    /// and a soft selection ring when tapped.
    private let compactRowHeight: CGFloat = 56

    private func compactDayCell(date: Date) -> some View {
        let subs = subscriptions(on: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dayNumber = calendar.component(.day, from: date)

        return VStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 28, height: 28)
                } else if isSelected {
                    Circle()
                        .strokeBorder(Color.red, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? Color.white : DesignTokens.label)
                    .monospacedDigit()
            }
            .frame(height: 28)

            DotRow(colors: subs.prefix(4).map(\.status.calendarColor),
                   overflow: max(0, subs.count - 4))
                .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compactRowHeight)
        .padding(.vertical, 2)
    }

    // MARK: - iOS Day Detail Section

    @ViewBuilder
    private var dayDetailSection: some View {
        let subs = subscriptions(on: detailDate)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(detailDate, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                Spacer()
                if !subs.isEmpty {
                    Text("\(subs.count) renewal\(subs.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.label3)
                        .monospacedDigit()
                }
            }

            if subs.isEmpty {
                Text("No renewals")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.label3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(subs.enumerated()), id: \.element.id) { index, sub in
                        detailRow(sub)
                        if index < subs.count - 1 {
                            Rectangle()
                                .fill(DesignTokens.contentDivider)
                                .frame(height: 0.5)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailRow(_ sub: Subscription) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(sub.category.map { Color(hex: $0.colorHex) } ?? Color(hex: "#8a8f99"))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: sub.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .lineLimit(1)
                Text(sub.billingCycle.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.label3)
            }

            Spacer()

            Text(sub.amount, format: .currency(code: sub.currencyCode))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.label)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    // MARK: - macOS Day Cell (event bars inline, like macOS Calendar)

    private func macDayCell(date: Date, height: CGFloat) -> some View {
        let subs = subscriptions(on: date)
        let isToday = calendar.isDateInToday(date)
        let hasSubscriptions = !subs.isEmpty

        return VStack(spacing: 2) {
            HStack {
                Spacer()
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? Color.red : DesignTokens.label)
                    .monospacedDigit()
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)

            if hasSubscriptions {
                VStack(spacing: 1) {
                    ForEach(subs.prefix(3)) { sub in
                        macEventBar(sub)
                    }
                    if subs.count > 3 {
                        Text("+\(subs.count - 3) more")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
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

    private func macEventBar(_ sub: Subscription) -> some View {
        let chipColor = sub.status.calendarColor
        return HStack(spacing: 3) {
            Circle()
                .fill(chipColor)
                .frame(width: 5, height: 5)
            Text(sub.name)
                .font(.system(size: 10))
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

// MARK: - Compact Dot Row

private struct DotRow: View {
    let colors: [Color]
    let overflow: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
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
