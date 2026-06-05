import Foundation

struct AppVersion: Equatable {
    static let missingValue = "—"

    let marketingVersion: String
    let buildNumber: String

    static var current: AppVersion {
        AppVersion()
    }

    var displayString: String {
        guard marketingVersion != Self.missingValue else { return Self.missingValue }
        guard buildNumber != Self.missingValue else { return marketingVersion }

        return "\(marketingVersion) (\(buildNumber))"
    }

    init(infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        marketingVersion = Self.versionValue(
            for: "CFBundleShortVersionString",
            in: infoDictionary
        )
        buildNumber = Self.versionValue(
            for: "CFBundleVersion",
            in: infoDictionary
        )
    }

    private static func versionValue(
        for key: String,
        in infoDictionary: [String: Any]
    ) -> String {
        guard let value = infoDictionary[key] as? String else {
            return missingValue
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? missingValue : trimmedValue
    }
}
