//
//  AccessibilityNotificationsManager+Config.swift
//  Onit
//
//  Created by Kévin Naudin on 23/01/2025.
//

import ApplicationServices

extension AccessibilityNotificationsManager {
    
    struct Config {
        
        static let debounceInterval: TimeInterval = 0.3 // 300ms
        
        static let notifications = [
            kAXAnnouncementRequestedNotification,
            kAXApplicationActivatedNotification,
            kAXApplicationDeactivatedNotification,
            kAXApplicationHiddenNotification,
            kAXApplicationShownNotification,
            kAXCreatedNotification,
            kAXDrawerCreatedNotification,
            kAXFocusedUIElementChangedNotification,
            kAXFocusedWindowChangedNotification,
            kAXHelpTagCreatedNotification,
            kAXLayoutChangedNotification,
            kAXMainWindowChangedNotification,
            kAXMenuClosedNotification,
            kAXMenuItemSelectedNotification,
            kAXMenuOpenedNotification,
            kAXMovedNotification,
            kAXResizedNotification,
            kAXRowCollapsedNotification,
            kAXRowCountChangedNotification,
            kAXRowExpandedNotification,
            kAXSelectedCellsChangedNotification,
            kAXSelectedChildrenChangedNotification,
            kAXSelectedChildrenMovedNotification,
            kAXSelectedColumnsChangedNotification,
            kAXSelectedRowsChangedNotification,
            kAXSelectedTextChangedNotification,
            kAXSheetCreatedNotification,
            kAXTitleChangedNotification,
            kAXUIElementDestroyedNotification,
            kAXUnitsChangedNotification,
            kAXValueChangedNotification,
            kAXWindowCreatedNotification,
            kAXWindowDeminiaturizedNotification,
            kAXWindowMiniaturizedNotification,
            kAXWindowMovedNotification,
            kAXWindowResizedNotification
        ]
    }
}
