import Foundation
import UserNotifications

class NotificationService {
    
    static let shared = NotificationService()
    private init() {}
    
    // MARK: - Permission Request
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Send Immediate Local Notification
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Turant trigger karne ke liye 1 second ka chhota sa delay (0 sahi kaam nahi karta kabhi kabhi)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Check karta hai ki user ne notifications on rakhi hain ya nahi (app ke apne settings se)
    var isEnabledInAppSettings: Bool {
        UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }
}
