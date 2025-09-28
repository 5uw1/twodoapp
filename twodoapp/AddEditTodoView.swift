import SwiftUI

struct AddEditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TodoStore

    let item: TodoItem?

    @State private var title: String
    @State private var emoji: String
    @State private var hasReminder: Bool
    @State private var dueDate: Date
    @State private var showEmojiPicker = false

    init(item: TodoItem? = nil) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _emoji = State(initialValue: item?.emoji ?? "📝")
        _hasReminder = State(initialValue: item?.dueDate != nil)
        _dueDate = State(initialValue: item?.dueDate ?? Self.defaultStartDate())
    }

    var body: some View {
        Form {
            Section("รายละเอียด") {
                HStack(spacing: 12) {
                    Button {
                        showEmojiPicker = true
                    } label: {
                        Text(emoji)
                            .font(.largeTitle)
                            .frame(width: 44, height: 44)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("เลือกอีโมจิ")

                    TextField("ชื่อรายการ", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
            }

            Section("การเตือน") {
                Toggle("ตั้งเตือน", isOn: $hasReminder.animation())
                if hasReminder {
                    DatePicker(
                        "วันและเวลา",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
        .navigationTitle(item == nil ? "เพิ่มรายการ" : "แก้ไขรายการ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("ยกเลิก") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("บันทึก") {
                    save()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView { selected in
                emoji = selected
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let reminderDate = hasReminder ? dueDate : nil

        if var existing = item {
            existing.title = trimmed
            existing.emoji = emoji
            existing.dueDate = reminderDate
            store.update(existing)
        } else {
            let newItem = TodoItem(title: trimmed, emoji: emoji, dueDate: reminderDate)
            store.add(newItem)
        }

        dismiss()
    }

    private static func defaultStartDate() -> Date {
        // เริ่มที่อีก 1 ชั่วโมงข้างหน้า
        Date().addingTimeInterval(3600)
    }
}
