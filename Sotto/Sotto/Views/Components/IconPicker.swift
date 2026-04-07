import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose an Icon")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 8), spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                        dismiss()
                    } label: {
                        Image(systemName: symbol)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
