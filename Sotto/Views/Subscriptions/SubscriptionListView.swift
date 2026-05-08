import SwiftUI
import SwiftData

struct SubscriptionListView: View {

    // MARK: - Properties

    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]
    @Query private var categories: [Category]
    @State private var selectedSubscription: Subscription?
    @State private var inspectorReady = false
    @State private var searchText = ""
    @State private var statusFilter: SubscriptionStatus? = .active
    @State private var categoryFilter: Category?
    @State private var showAddSheet = false

    @Environment(\.modelContext) private var modelContext
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

    // MARK: - Computed Properties

    private var filteredSubscriptions: [Subscription] {
        subscriptions.filter { sub in
            let matchesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil || sub.status == statusFilter
            let matchesCategory = categoryFilter == nil || sub.category?.id == categoryFilter?.id
            return matchesSearch && matchesStatus && matchesCategory
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if inspectorReady {
                listContent
                    .inspector(isPresented: Binding(
                        get: { selectedSubscription != nil },
                        set: { if !$0 { selectedSubscription = nil } }
                    )) {
                        if let sub = selectedSubscription {
                            InspectorPane(subscription: sub)
                        }
                    }
            } else {
                listContent
            }
        }
        // .task runs asynchronously on the next actor turn, after the
        // tab-switch layout pass completes, so .inspector's NSSplitViewController
        // backing is never created during an in-progress AppKit layout.
        .task { inspectorReady = true }
    }

    // MARK: - Private Views

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: isCompact ? [] : [.sectionHeaders]) {
                Section {
                    if filteredSubscriptions.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSubscriptions) { subscription in
                            SubscriptionRow(
                                subscription: subscription,
                                isSelected: selectedSubscription?.id == subscription.id,
                                isCompact: isCompact
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSubscription?.id == subscription.id {
                                    selectedSubscription = nil
                                } else {
                                    selectedSubscription = subscription
                                }
                            }
                            .contextMenu {
                                subscriptionContextMenuItems(for: subscription)
                            }

                            Rectangle()
                                .fill(DesignTokens.contentDivider)
                                .frame(height: 0.5)
                        }
                    }
                } header: {
                    if !isCompact {
                        columnHeader
                    }
                }
            }
        }
        .background(DesignTokens.windowBackground)
        #if os(iOS)
        .safeAreaPadding(.bottom, 64)
        #endif
        .searchable(text: $searchText, prompt: "Search subscriptions")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
        }
        .navigationTitle("All Subscriptions")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddSheet = true
            } label: {
                Label("Add Subscription", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag(nil as SubscriptionStatus?)
                    ForEach(SubscriptionStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as SubscriptionStatus?)
                    }
                }
                Picker("Category", selection: $categoryFilter) {
                    Text("All Categories").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        #else
        ToolbarItem {
            Button {
                showAddSheet = true
            } label: {
                Label("Add Subscription", systemImage: "plus")
            }
        }
        ToolbarItem {
            Picker("Status", selection: $statusFilter) {
                Text("All").tag(nil as SubscriptionStatus?)
                ForEach(SubscriptionStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status as SubscriptionStatus?)
                }
            }
        }
        ToolbarItem {
            Picker("Category", selection: $categoryFilter) {
                Text("All Categories").tag(nil as Category?)
                ForEach(categories) { category in
                    Text(category.name).tag(category as Category?)
                }
            }
        }
        #endif
    }

    private var emptyState: some View {
        let hasFilter = !searchText.isEmpty || statusFilter != .active || categoryFilter != nil
        return ContentUnavailableView {
            Label(hasFilter ? "No matches" : "No subscriptions yet",
                  systemImage: hasFilter ? "magnifyingglass" : "list.bullet.rectangle")
        } description: {
            Text(hasFilter
                 ? "Try clearing filters or searching for a different name."
                 : "Track services you pay for. Tap + to add your first subscription.")
        } actions: {
            if !hasFilter {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Subscription", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Column Header

    private var columnHeader: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 36, height: 0)
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Cycle")
                .frame(width: 130, alignment: .leading)
            Text("Next renewal")
                .frame(width: 130, alignment: .leading)
            Text("Amount")
                .frame(width: 110, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(DesignTokens.label3)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(DesignTokens.windowBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.contentDivider)
                .frame(height: 0.5)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private func subscriptionContextMenuItems(for subscription: Subscription) -> some View {
        if subscription.status == .active {
            Button("Pause") { subscription.status = .paused; subscription.updatedAt = Date() }
        }
        if subscription.status == .paused {
            Button("Resume") { subscription.status = .active; subscription.updatedAt = Date() }
        }
        if subscription.status != .cancelled {
            Button("Cancel Subscription") { subscription.status = .cancelled; subscription.updatedAt = Date() }
        }
        Divider()
        Button("Delete", role: .destructive) { deleteSubscription(subscription) }
    }

    // MARK: - Helpers

    private func deleteSubscription(_ subscription: Subscription) {
        if selectedSubscription?.id == subscription.id {
            selectedSubscription = nil
        }
        modelContext.delete(subscription)
    }
}

#Preview {
    NavigationStack {
        SubscriptionListView()
    }
    .modelContainer(makePreviewContainer())
}

