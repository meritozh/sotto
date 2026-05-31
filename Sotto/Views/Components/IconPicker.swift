import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    // MARK: - Properties

    private let symbols = [
        "play.tv", "film", "music.note", "headphones",
        "laptopcomputer", "desktopcomputer", "keyboard", "printer",
        "cloud", "externaldrive", "server.rack",
        "gamecontroller", "puzzlepiece",
        "newspaper", "book", "graduationcap",
        "bolt", "lightbulb", "wifi", "phone",
        "heart", "figure.run", "dumbbell",
        "cart", "bag", "creditcard",
        "house", "car", "airplane",
        "envelope", "bell", "lock.shield",
        "paintbrush", "camera", "wand.and.stars",
        "ellipsis.circle"
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button {
                            selectedIcon = symbol
                            dismiss()
                        } label: {
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedIcon == symbol ? Color.accentColor.opacity(0.18) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(macOS)
        .frame(width: 400, height: 300)
        #else
        .presentationDetents([.height(360), .medium])
        .presentationDragIndicator(.visible)
        #endif
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    }

    private var title: String {
        locale.identifier.lowercased().hasPrefix("zh") ? "选择图标" : "Choose an Icon"
    }
}

#Preview {
    @Previewable @State var icon = "laptopcomputer"
    IconPicker(selectedIcon: $icon)
}
