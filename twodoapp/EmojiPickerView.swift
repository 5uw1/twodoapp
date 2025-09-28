import SwiftUI

struct EmojiPickerView: View {
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let emojis: [String] = [
        "📝","✅","📌","⭐️","🔥","💡","📚","🛒","🍽️","🏃‍♂️","💪","🧹","🧼","🧽","🧺",
        "💻","📱","🖥️","📧","📞","🗓️","⏰","🕒","🎵","🎮","🎬","✈️","🚗","🚲","🏠",
        "🌱","🌟","🎯","🧠","💤","💊","💰","📦","🧾","🧪","🧑‍🍳","🧑‍🏫","🧑‍💻","🧑‍🎓"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            onPick(emoji)
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("เลือกอีโมจิ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
