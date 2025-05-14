//
//  DateHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import Foundation

// Shared DateFormatter instances for reuse, because it's expensive to recreate
// it several times throughout the app's lifetime.
struct DateFormatters {
    static let base: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // Common configurations
    static let medium: DateFormatter = {
        let formatter = base.copy() as! DateFormatter
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let mediumWithTime: DateFormatter = {
        let formatter = base.copy() as! DateFormatter
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Add other common formats as needed
}

func convertEpochDateToCleanDate(
    epochDate: Double,
    dateStyle: DateFormatter.Style = DateFormatter.Style.medium,
    timeStyle: DateFormatter.Style = DateFormatter.Style.none
) -> String {
    let date = Date(timeIntervalSince1970: epochDate)

    if dateStyle == .medium && timeStyle == .none {
        return DateFormatters.medium.string(from: date)
    } else {
        let formatter = DateFormatters.base.copy() as! DateFormatter
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        
        return formatter.string(from: date)
    }
}

func getTodayAsEpochDate() -> Double {
    let today = Date()
    let todayAsEpochDate = today.timeIntervalSince1970
    return todayAsEpochDate
}
