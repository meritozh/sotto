import SwiftUI
import SwiftData

struct CalendarView: View {

    // MARK: - Properties

    @Query private var allSubscriptions: [Subscription]
    @Binding var selectedSubscription: Subscription?
    @State private var displayedMonth = Date()

    // MARK: - Computed Properties

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.activeOnly
    }

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

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
        return activeSubscriptions.filter { calendar.startOfDay(for: $0.nextDueDate) == startOfDay }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
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
                    .frame(minWidth: 200)

                Button {
                    if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = newMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)

                Button("Today") {
                    displayedMonth = Date()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            // Weekday headers
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

            Divider()

            // Day grid — fills remaining space
            GeometryReader { geo in
                let totalRows = CGFloat((leadingEmptyDays + daysInMonth.count + 6) / 7)
                let rowHeight = max(48, geo.size.height / totalRows)

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
        .navigationTitle("Calendar")
    }

    // MARK: - Private Views

    private func dayCell(date: Date, height: CGFloat) -> some View {
        let subs = subscriptions(on: date)
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 2) {
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
            Spacer(minLength: 0)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(!subs.isEmpty ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onTapGesture {
            if let first = subs.first {
                selectedSubscription = first
            }
        }
    }
}
