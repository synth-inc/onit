//
//  Model+Timer.swift
//  Onit
//
//  Created by Benjamin Sage on 11/2/24.
//

import Foundation

extension OnitModel {
    func startTrustedTimer() {
        trustedTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let currentStatus = Accessibility.trusted
                if self?.trusted != currentStatus {
                    self?.trusted = currentStatus
                }
            }
    }
}
