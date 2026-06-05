//
//  WakeNotifier.swift
//  WakeyThree
//
//  macOS wake feedback. Waking happens from the menu bar, which dismisses on
//  click, so a user notification is the reliable way to report the outcome
//  (especially actionable failures like missing Local Network permission).
//

#if os(macOS)
import Foundation
import UserNotifications

enum WakeNotifier {
    static func report(_ result: Result<Void, NetworkError>, serverName: String) {
        let message = WakeMessage(result: result, serverName: serverName)
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert]) { granted, error in
            if let error {
                Logger.shared.logWarning(message: "Notification authorization error: \(error)")
            }
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            center.add(request)
        }
    }
}
#endif
