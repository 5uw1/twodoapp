import Foundation
import UserNotifications

actor LocalNotificationManager {
    static let shared = LocalNotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func scheduleNotification(id: String?, title: String, fireAt date: Date) async throws -> String {
        let identifier = id ?? UUID().uuidString

        // หากเคยตั้งไว้ด้วย id เดิม ให้ยกเลิกก่อน
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        // สร้าง trigger จากวัน/เวลา (ครั้งเดียว)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        return identifier
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
