import SwiftUI
import SwiftData

struct CategoriesView: View {

    // MARK: - Properties

    @Query private var categories: [Category]
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCategory = false
    @State private var editingCategory: Category?
    @State private var newName = ""
    @State private var newColorHex = "#4ECDC4"
    @State private var newIcon = "tag"

    // MARK: - Body

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .frame(width: 32)

                    VStack(alignment: .leading) {
                        Text(category.name)
                            .fontWeight(.medium)
                        Text("\(category.subscriptions.count) subscriptions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    let total = category.subscriptions
                        .filter { $0.status == .active }
                        .reduce(Decimal.zero) { $0 + BillingCycleCalculator.monthlyEquivalent(amount: $1.amount, cycle: $1.billingCycle) }

                    if total > 0 {
                        Text(total, format: .currency(code: baseCurrency))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("/mo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 12, height: 12)
                }
                .contextMenu {
                    Button("Edit") { editingCategory = category }
                    Button("Delete", role: .destructive) { modelContext.delete(category) }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            Button {
                showAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAddCategory) {
            categoryForm(editing: nil)
        }
        .sheet(item: $editingCategory) { category in
            categoryForm(editing: category)
        }
    }

    // MARK: - Private Views

    private func categoryForm(editing: Category?) -> some View {
        let isEditing = editing != nil

        return NavigationStack {
            Form {
                TextField("Name", text: $newName)
                TextField("Color (hex)", text: $newColorHex)
                HStack {
                    Text("Preview:")
                    Circle().fill(Color(hex: newColorHex)).frame(width: 20, height: 20)
                }
                TextField("SF Symbol", text: $newIcon)
                HStack {
                    Text("Preview:")
                    Image(systemName: newIcon)
                        .font(.title2)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddCategory = false
                        editingCategory = nil
                        resetForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if let category = editing {
                            category.name = newName
                            category.colorHex = newColorHex
                            category.icon = newIcon
                        } else {
                            let category = Category(name: newName, colorHex: newColorHex, icon: newIcon)
                            modelContext.insert(category)
                        }
                        showAddCategory = false
                        editingCategory = nil
                        resetForm()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 320)
        #endif
        .onAppear {
            if let category = editing {
                newName = category.name
                newColorHex = category.colorHex
                newIcon = category.icon
            } else {
                resetForm()
            }
        }
    }

    // MARK: - Helpers

    private func resetForm() {
        newName = ""
        newColorHex = "#4ECDC4"
        newIcon = "tag"
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
    .modelContainer(makePreviewContainer())
}
