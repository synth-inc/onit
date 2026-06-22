//
//  NumberHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 8/22/25.
//

import Foundation

struct NumberHelpers {
    static func roundDoubleToNthPlace(
        number: Double,
        place: Int = 2
    ) -> String {
        return String(format: "%.\(place)f", number)
    }
}
