import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var emoji: String
    var dueDate: Date?
    var isCompleted: Bool
    var notificationId: String?

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String = "📝",
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        notificationId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notificationId = notificationId
    }
}
