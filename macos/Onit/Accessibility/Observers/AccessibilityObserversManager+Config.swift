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
            kAXWindowMovedNotification,
            kAXWindowResizedNotification,
            kAXWindowCreatedNotification,
            kAXUIElementDestroyedNotification
            //            kAXFocusedUIElementChangedNotification,
            //            kAXSelectedColumnsChangedNotification,
            //            kAXSelectedRowsChangedNotification,

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

        static let persistentNotifications: [String] = [
            kAXWindowDeminiaturizedNotification,
            kAXWindowMiniaturizedNotification,
        ]
    }
}
