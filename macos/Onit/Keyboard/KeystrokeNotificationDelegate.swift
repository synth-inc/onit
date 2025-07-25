//
//  KeystrokeNotificationDelegate.swift
//  Onit
//
//  Created by Assistant on 12/9/2024.
//

import Foundation
import AppKit

@MainActor protocol KeystrokeNotificationDelegate: AnyObject {
    func keystrokeNotificationManager(_ manager: KeystrokeNotificationManager, didReceiveKeystroke event: KeystrokeEvent)
} 