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
        NavigationStack {
            formContent
                .navigationTitle("New Payment Method")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: save)
                            .keyboardShortcut(.defaultAction)
                            .disabled(name.isEmpty)
                    }
                }
        }
        #if os(macOS)
        .frame(width: 360, height: 240)
        #endif
    }

    private var formContent: some View {
        Form {
            TextField("Name (e.g. Chase Visa)", text: $name)
            Picker("Type", selection: $type) {
                ForEach(PaymentMethodType.allCases, id: \.self) { methodType in
                    Text(methodType.displayName).tag(methodType)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func save() {
        let method = PaymentMethod(name: name, type: type)
        onSave(method)
        isPresented = false
    }
}

#Preview {
    @Previewable @State var shown = true
    PaymentMethodForm(isPresented: $shown) { _ in }
}
