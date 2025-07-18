//
//  StringHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 7/18/25.
//

struct StringHelpers {
    static func removeWhiteSpaceAndNewLines(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\r?\\n", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
