//
//  KeystrokeNotificationDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/24/25.
//

import Foundation
import AppKit

@MainActor protocol KeystrokeNotificationDelegate: AnyObject {
    func keystrokeNotificationManager(_ manager: KeystrokeNotificationManager, didReceiveKeystroke event: KeystrokeEvent)
} 
