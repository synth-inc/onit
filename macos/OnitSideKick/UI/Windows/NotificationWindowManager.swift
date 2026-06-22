//
//  NotificationWindowManager.swift
//  Onit
//
//  Created by Loyd Kim on 10/6/25.
//

import AppKit

@MainActor
@Observable
final class NotificationWindowManager {
    // MARK: - Singleton
    
    static let shared = NotificationWindowManager()
    
    // MARK: - Private Variables
    
    @ObservationIgnored
    private var notificationWindows: [NotificationWindow] = []
    
    // MARK: - Public Functions
    
    func createWindow(
        titleKey: String,
        captionKey: String? = nil,
        image: ImageResource? = nil,
        primaryAction: NotificationWindowView.Action? = nil,
        secondaryAction: NotificationWindowView.Action? = nil,
        closeButtonCallback: (() -> Void)? = nil,
        namedIdentifier: String? = nil,
        enterAnimation: NotificationWindowAnimation? = nil,
        dismissAnimation: NotificationWindowAnimation? = nil
    ) {
        let notificationWindow = NotificationWindow(
            titleKey: titleKey,
            captionKey: captionKey,
            image: image,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            closeButtonCallback: closeButtonCallback,
            namedIdentifier: namedIdentifier,
            enterAnimation: enterAnimation,
            dismissAnimation: dismissAnimation
        )

        notificationWindow.showNotification()

        self.notificationWindows.append(notificationWindow)
    }
    
    func getWindows(referencing namedIdentifier: String) -> [NotificationWindow] {
        let identifiedNotificationWindows = self.notificationWindows.filter {
            $0.namedIdentifier == namedIdentifier
        }
        return identifiedNotificationWindows
    }
    
    func closeWindow(createdAt: Date) {
        guard let notificationWindow = self.notificationWindows.first(where: { $0.createdAt == createdAt })
        else { return }
        
        notificationWindow.dismissNotification() {
            self.notificationWindows.removeAll { $0 === notificationWindow }
        }
    }
    
    func closeWindows(referencing namedIdentifier: String) {
        let identifiedNotificationWindows = self.getWindows(referencing: namedIdentifier)
        
        for notificationWindow in identifiedNotificationWindows {
            notificationWindow.dismissNotification() {
                self.notificationWindows.removeAll { $0 === notificationWindow }
            }
        }
    }
}
