import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: String

    // MARK: - Properties

    static let currencies: [(code: String, name: LocalizedStringResource)] = [
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

    // MARK: - Body

    var body: some View {
        Picker("Currency", selection: $selectedCurrency) {
            ForEach(Self.currencies, id: \.code) { currency in
                HStack(spacing: 0) {
                    Text(verbatim: "\(currency.code) - ")
                    Text(currency.name)
                }
                    .tag(currency.code)
            }
        }
    }
}

#Preview {
    @Previewable @State var currency = "USD"
    Form {
        CurrencyPicker(selectedCurrency: $currency)
    }
    .formStyle(.grouped)
    .frame(width: 400)
}
