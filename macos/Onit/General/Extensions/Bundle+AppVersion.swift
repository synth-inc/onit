//
//  Bundle+AppVersion.swift
//  Onit
//
//  Created by Jay Swanson on 6/17/25.
//

import Foundation

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
