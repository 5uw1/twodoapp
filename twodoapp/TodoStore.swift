import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("todos.json")
    }()

    init(preview: Bool = false) {
        if preview {
            self.items = [
                TodoItem(title: "ทดสอบงาน", emoji: "✅", dueDate: Date().addingTimeInterval(3600)),
                TodoItem(title: "ซื้อของเข้าบ้าน", emoji: "🛒"),
                TodoItem(title: "อ่านหนังสือ 30 นาที", emoji: "📚", dueDate: Date().addingTimeInterval(7200))
            ]
        } else {
            load()
        }
    }

    func add(_ newItem: TodoItem) {
        var item = newItem
        items.append(item)
        save()

        Task {
            await scheduleIfNeeded(&item)
            replace(item)
            save()
        }
    }

    func update(_ updated: TodoItem) {
        var item = updated
        replace(item)
        save()

        Task {
            await scheduleIfNeeded(&item)
            replace(item)
            save()
        }
    }

    func toggleComplete(_ target: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == target.id }) else { return }
        var item = items[idx]
        item.isCompleted.toggle()

        // เมื่อทำเสร็จแล้ว ยกเลิกการเตือน (ถ้ามี)
        if item.isCompleted, let nid = item.notificationId {
            Task { await LocalNotificationManager.shared.cancelNotification(id: nid) }
            item.notificationId = nil
        }

        items[idx] = item
        save()
    }

    func delete(_ item: TodoItem) {
        if let nid = item.notificationId {
            Task { await LocalNotificationManager.shared.cancelNotification(id: nid) }
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    func delete(where shouldDelete: (TodoItem) -> Bool) {
        let toDelete = items.filter(shouldDelete)
        for item in toDelete {
            if let nid = item.notificationId {
                Task { await LocalNotificationManager.shared.cancelNotification(id: nid) }
            }
        }
        items.removeAll(where: shouldDelete)
        save()
    }

    // MARK: - Persistence

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([TodoItem].self, from: data)
            self.items = decoded
        } catch {
            self.items = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // เก็บเงียบๆ เพื่อไม่ให้รบกวนผู้ใช้
            // สามารถเพิ่มการ log ได้ในอนาคต
        }
    }

    // MARK: - Helpers

    private func replace(_ item: TodoItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
    }

    private func scheduleIfNeeded(_ item: inout TodoItem) async {
        if let date = item.dueDate, date > Date() {
            do {
                let id = try await LocalNotificationManager.shared.scheduleNotification(
                    id: item.notificationId,
                    title: "\(item.emoji) \(item.title)",
                    fireAt: date
                )
                item.notificationId = id
            } catch {
                // หากตั้งเตือนไม่ได้ ก็ปล่อยรายการไว้โดยไม่มี notificationId
            }
        } else if let nid = item.notificationId {
            await LocalNotificationManager.shared.cancelNotification(id: nid)
            item.notificationId = nil
        }
    }
}
