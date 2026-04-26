import Foundation

extension Subscription {
    var daysUntilDue: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: nextDueDate)
        ).day ?? 0
    }
}

extension [Subscription] {
    var activeOnly: [Subscription] {
        filter { $0.status == .active }
    }
}
