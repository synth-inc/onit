//
//  AccessibilityObserversManager+Config.swift
//  Onit
//
//  Created by Kévin Naudin on 08/05/2025.
//

import ApplicationServices

extension AccessibilityObserversManager {

    struct Config {
        
        static let notifications: [String] = [
            kAXFocusedWindowChangedNotification,
            kAXMainWindowChangedNotification,
            kAXSelectedTextChangedNotification,
            kAXValueChangedNotification,
            kAXFocusedUIElementChangedNotification,
            kAXWindowMovedNotification,
            kAXWindowResizedNotification,
            kAXWindowCreatedNotification,
            kAXUIElementDestroyedNotification,
            kAXTitleChangedNotification

//            kAXSelectedColumnsChangedNotification,
//            kAXSelectedRowsChangedNotification,
//            kAXAnnouncementRequestedNotification,
//            kAXApplicationActivatedNotification,
//            kAXApplicationDeactivatedNotification,
//            kAXApplicationHiddenNotification,
//            kAXApplicationShownNotification,
//            kAXCreatedNotification,
//            kAXDrawerCreatedNotification,
//            kAXHelpTagCreatedNotification,
//            kAXLayoutChangedNotification,
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
//            kAXUnitsChangedNotification,
//            kAXWindowDeminiaturizedNotification,
//            kAXWindowMiniaturizedNotification
        ]

        static let persistentNotifications: [String] = [
            kAXWindowDeminiaturizedNotification,
            kAXWindowMiniaturizedNotification,
        ]

        // We want to collect typeahead tests from both Onit and ignore processes.
        static let onitNotifications: [String] = [
            kAXValueChangedNotification,
            kAXFocusedUIElementChangedNotification,
        ]
    }
}
