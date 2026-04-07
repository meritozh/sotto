import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var allSubscriptions: [Subscription]
    @Binding var selectedSubscription: Subscription?
    @State private var displayedMonth = Date()

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.filter { $0.status == .active }
    }

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
