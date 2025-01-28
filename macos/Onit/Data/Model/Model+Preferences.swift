//
//  Model+Preferences.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Foundation

extension OnitModel {
    var preferences: Preferences {
        get {
            access(keyPath: \.preferences)
            return Preferences.shared
        }
        set {
            withMutation (keyPath: \.preferences) {
                newValue.save()
            }
        }
    }
}
