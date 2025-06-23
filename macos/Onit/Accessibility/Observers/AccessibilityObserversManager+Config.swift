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
            kAXUIElementDestroyedNotification,
            kAXTitleChangedNotification,
            kAXFocusedUIElementChangedNotification,

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
        
        // We want to collect typeahead tests from both Onit and ignore processes.
        static let onitNotifications: [String] = [
            kAXValueChangedNotification,
            kAXFocusedUIElementChangedNotification,
        ]

        static let untrackedAppNotifications: [String] = [
            // I wanted to collect typeahead test cases for xcode, but we still can't due to the console causing infinite loops.
            // Some value change, which causes print statements in console, which creates more 'value changed' events, which cause more print statements, etc etc.
            // This creates infinite loops. So we'll have to do the typeahead history without xcode.
//            kAXValueChangedNotification,
//            kAXFocusedUIElementChangedNotification,
        ]
        
        static let persistentNotifications: [String] = [
            kAXWindowDeminiaturizedNotification,
            kAXWindowMiniaturizedNotification,
        ]
    }
}
