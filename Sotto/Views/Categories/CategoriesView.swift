import SwiftUI
import SwiftData

struct CategoriesView: View {

    // MARK: - Properties

    @Query private var categories: [Category]
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCategory = false
    @State private var editingCategory: Category?
    @State private var newEnglishName = ""
    @State private var newChineseName = ""
    @State private var newColor = Color(hex: "#4ECDC4")
    @State private var newIcon = "tag"
    @State private var showIconPicker = false
    @State private var categoryPendingDeletion: Category?

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
        .alert(item: $categoryPendingDeletion) { category in
            Alert(
                title: Text("Delete \(category.localizedName(for: locale))?"),
                message: Text("Subscriptions in this category will become uncategorized. This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteCategory(category)
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    categoryPendingDeletion = nil
                }
            )
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
                                categoryPendingDeletion = category
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
                Text(category.localizedName(for: locale))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .lineLimit(1)
                Spacer()
                categoryActionsMenu(for: category)
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

    private func categoryActionsMenu(for category: Category) -> some View {
        Menu {
            Button {
                editingCategory = category
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                categoryPendingDeletion = category
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DesignTokens.label3)
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Category Actions"))
    }

    private func categoryForm(editing: Category?) -> some View {
        let isEditing = editing != nil

        return NavigationStack {
            Form {
                TextField("English Name", text: $newEnglishName)
                TextField("Chinese Name", text: $newChineseName)

                ColorPicker("Color", selection: $newColor, supportsOpacity: false)

                Button {
                    showIconPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Text("Icon")
                        Spacer()
                        Image(systemName: newIcon)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28, height: 28)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.label3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .formStyle(.grouped)
            #if os(iOS)
            .sheet(isPresented: $showIconPicker) {
                IconPicker(selectedIcon: $newIcon)
            }
            #else
            .popover(isPresented: $showIconPicker) {
                IconPicker(selectedIcon: $newIcon)
            }
            #endif
            .navigationTitle(isEditing ? LocalizedStringKey("Edit Category") : LocalizedStringKey("New Category"))
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
                    Button {
                        let englishName = newEnglishName.categoryFormTrimmed
                        let chineseName = newChineseName.categoryFormTrimmed
                        let categoryName = Category.canonicalName(
                            english: englishName,
                            chineseSimplified: chineseName
                        )
                        let savedCategoryName = categoryName.isEmpty ? editing?.name ?? "" : categoryName
                        let colorHex = newColor.hexRGB ?? "#4ECDC4"

                        if let category = editing {
                            category.name = savedCategoryName
                            category.nameEnglish = englishName
                            category.nameChineseSimplified = chineseName
                            category.colorHex = colorHex
                            category.icon = newIcon
                        } else {
                            let category = Category(
                                name: savedCategoryName,
                                colorHex: colorHex,
                                icon: newIcon,
                                nameEnglish: englishName,
                                nameChineseSimplified: chineseName
                            )
                            modelContext.insert(category)
                        }
                        showAddCategory = false
                        editingCategory = nil
                        resetForm()
                    } label: {
                        Text(isEditing ? LocalizedStringKey("Save") : LocalizedStringKey("Add"))
                    }
                    .disabled(!hasValidCategoryName(isEditing: isEditing))
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 320)
        #endif
        .onAppear {
            if let category = editing {
                let legacyName = legacyLocalizedNames(from: category.name)
                let englishName = category.nameEnglish.categoryFormTrimmed
                let chineseName = category.nameChineseSimplified.categoryFormTrimmed

                if category.hasDefaultLocalizedName && !category.hasLocalizedNameOverrides {
                    newEnglishName = ""
                    newChineseName = ""
                } else {
                    newEnglishName = englishName.isEmpty && chineseName.isEmpty ? legacyName.english : englishName
                    newChineseName = englishName.isEmpty && chineseName.isEmpty ? legacyName.chinese : chineseName
                }
                newColor = Color(hex: category.colorHex)
                newIcon = category.icon
            } else {
                resetForm()
            }
        }
    }

    // MARK: - Helpers

    private func hasValidCategoryName(isEditing: Bool) -> Bool {
        isEditing || !Category.canonicalName(english: newEnglishName, chineseSimplified: newChineseName).isEmpty
    }

    private func resetForm() {
        newEnglishName = ""
        newChineseName = ""
        newColor = Color(hex: "#4ECDC4")
        newIcon = "tag"
        showIconPicker = false
    }

    private func deleteCategory(_ category: Category) {
        for subscription in category.subscriptions ?? [] {
            subscription.category = nil
        }
        if editingCategory?.id == category.id {
            editingCategory = nil
        }
        modelContext.delete(category)
        categoryPendingDeletion = nil
    }

    private func legacyLocalizedNames(from name: String) -> (english: String, chinese: String) {
        let trimmedName = name.categoryFormTrimmed
        let containsCJK = trimmedName.range(
            of: "\\p{Han}",
            options: .regularExpression
        ) != nil

        return containsCJK ? ("", trimmedName) : (trimmedName, "")
    }
}

private extension String {
    var categoryFormTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
    .modelContainer(makePreviewContainer())
}
