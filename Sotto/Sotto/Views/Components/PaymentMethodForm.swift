import SwiftUI
import SwiftData

struct PaymentMethodForm: View {

    // MARK: - Properties

    @Binding var isPresented: Bool
    let onSave: (PaymentMethod) -> Void

    @State private var name = ""
    @State private var type = PaymentMethodType.credit

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Text("New Payment Method")
                .font(.headline)

            Form {
                TextField("Name (e.g. Chase Visa)", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(PaymentMethodType.allCases, id: \.self) { methodType in
                        Text(methodType.rawValue.capitalized).tag(methodType)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    let method = PaymentMethod(name: name, type: type)
                    onSave(method)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 360, height: 240)
    }
}
