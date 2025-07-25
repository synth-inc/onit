//
//  MouseNotificationDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/25/25.
//

import Foundation
import AppKit

@MainActor protocol MouseNotificationDelegate: AnyObject {
    func mouseNotificationManager(_ manager: MouseNotificationManager, didReceiveSingleClick event: NSEvent)
    func mouseNotificationManager(_ manager: MouseNotificationManager, didReceiveDoubleClick event: NSEvent)
    func mouseNotificationManager(_ manager: MouseNotificationManager, didReceiveTripleClick event: NSEvent)
    func mouseNotificationManager(_ manager: MouseNotificationManager, didStartDrag event: NSEvent)
    func mouseNotificationManager(_ manager: MouseNotificationManager, didUpdateDrag event: NSEvent)
    func mouseNotificationManager(_ manager: MouseNotificationManager, didEndDrag event: NSEvent)
}

