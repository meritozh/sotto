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
            LazyVStack(spacing: 0) {
                ForEach(filteredSubscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                        .padding(.horizontal)
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

                    Divider()
                        .padding(.leading)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search subscriptions")
        .toolbar {
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
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
        }
        .navigationTitle("All Subscriptions")
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

