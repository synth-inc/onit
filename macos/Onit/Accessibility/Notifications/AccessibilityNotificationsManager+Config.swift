//
//  AccessibilityNotificationsManager+Config.swift
//  Onit
//
//  Created by Kévin Naudin on 23/01/2025.
//

import ApplicationServices

extension AccessibilityNotificationsManager {

    struct Config {

        static let debounceInterval: TimeInterval = 0.3  // 300ms
        static let typingDebounceInterval: TimeInterval = 1.0 // 1s
    }
}
