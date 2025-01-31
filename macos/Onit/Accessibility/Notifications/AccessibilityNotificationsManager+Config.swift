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
            kAXFocusedUIElementChangedNotification,
            kAXSelectedTextChangedNotification,
            kAXValueChangedNotification,
            kAXSelectedColumnsChangedNotification,
            kAXSelectedRowsChangedNotification,
            
//            kAXAnnouncementRequestedNotification,
//            kAXApplicationActivatedNotification,
//            kAXApplicationDeactivatedNotification,
//            kAXApplicationHiddenNotification,
//            kAXApplicationShownNotification,
//            kAXCreatedNotification,
//            kAXDrawerCreatedNotification,
//            kAXFocusedWindowChangedNotification,
//            kAXHelpTagCreatedNotification,
//            kAXLayoutChangedNotification,
//            kAXMainWindowChangedNotification,
//            kAXMenuClosedNotification,
//            kAXMenuItemSelectedNotification,
//            kAXMenuOpenedNotification,
//            kAXMovedNotification,
//            kAXResizedNotification,
//            kAXRowCollapsedNotification,
//            kAXRowCountChangedNotification,
//            kAXRowExpandedNotification,
//            kAXSelectedCellsChangedNotification,
//            kAXSelectedChildrenChangedNotification,
//            kAXSelectedChildrenMovedNotification,
//            kAXSheetCreatedNotification,
//            kAXTitleChangedNotification, // Used
//            kAXUIElementDestroyedNotification,
//            kAXUnitsChangedNotification,
//            kAXWindowCreatedNotification,
//            kAXWindowDeminiaturizedNotification,
//            kAXWindowMiniaturizedNotification,
//            kAXWindowMovedNotification,
//            kAXWindowResizedNotification
        ]
    }
}
