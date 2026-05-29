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

    private var gridColumns: [GridItem] {
        if isCompact {
            return [GridItem(.flexible(), spacing: 12)]
        }
        return [GridItem(.adaptive(minimum: 200, maximum: 320), spacing: 12)]
    }

    // MARK: - Body

    var body: some View {
        categoryList
        .background(DesignTokens.windowBackground)
        .floatingTabBarContentClearance()
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem {
                Button {
                    showAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            categoryForm(editing: nil)
        }
        .sheet(item: $editingCategory) { category in
            categoryForm(editing: category)
        }
    }

    private var categoryList: some View {
        ScrollView {
            LazyVGrid(
                columns: gridColumns,
                alignment: isCompact ? .center : .leading,
                spacing: 12
            ) {
                ForEach(categories) { category in
                    categoryCard(category)
                        .contextMenu {
                            Button {
                                editingCategory = category
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, isCompact ? 0 : 18)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Private Views

    private func categoryCard(_ category: Category) -> some View {
        let subs = category.subscriptions ?? []
        let total = subs
            .filter { $0.status == .active }
            .reduce(Decimal.zero) { $0 + BillingCycleCalculator.monthlyEquivalent(amount: $1.amount, cycle: $1.billingCycle) }
        let count = subs.count

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                Text(category.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                Spacer()
            }

            Text("\(count) subscriptions")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.label3)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(total, format: .currency(code: baseCurrency))
                    .font(.system(size: 22, weight: .semibold))
                    .monospacedDigit()
                    .kerning(-0.4)
                    .foregroundStyle(DesignTokens.label)
                Text("/mo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignTokens.label3)
            }
            .padding(.top, 2)
        }
        .cardStyle(paddingH: 14, paddingV: 14)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
    }

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
