import SwiftUI
import TipKit

struct AddFirstSubscriptionTip: Tip {
    @Parameter
    static var subscriptionCount: Int = 0

    static let addActionID = "add"

    var title: Text {
        Text("Add Your First Subscription")
    }

    var message: Text? {
        Text("Track a service you pay for and see your monthly spend at a glance.")
    }

    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }

    var actions: [Action] {
        Action(id: Self.addActionID, title: "Add Subscription")
    }

    var rules: [Rule] {
        #Rule(Self.$subscriptionCount) { $0 == 0 }
    }
}
