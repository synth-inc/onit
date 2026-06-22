//
//  DateHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import Foundation

struct DateHelpers {
    static func getExpirationDate(
        startDate: Date = Date(),
        expiresIn expirationTime: TimeInterval
    ) -> Date {
        return startDate.addingTimeInterval(expirationTime)
    }
    
    static func getRemainingTimeInSeconds(
        startDate: Date = Date(),
        endDate: Date
    ) -> TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    static func formatDateToTimeRemaining(_ date: Date) -> String {
        let timeSinceNow = max(0, Int(date.timeIntervalSinceNow.rounded()))
        let hours = timeSinceNow / 3600
        let minutes = (timeSinceNow % 3600) / 60
        let seconds = timeSinceNow % 60
        
        if hours > 0 {
            return "\(hours) \(hours == 1 ? "hr" : "hrs")"
        } else if minutes > 0 {
            return "\(minutes) \(minutes == 1 ? "min" : "mins")"
        } else {
            return "\(seconds) \(seconds == 1 ? "sec" : "secs")"
        }
    }
    
    static func formatDateToTimeOfDay(_ date: Date) -> String {
        let calendar = Calendar.current
        var hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let period = hour >= 12 ? "pm" : "am"
        
        if hour == 0 {
            hour = 12
        } else if hour > 12 {
            hour -= 12
        }
        
        if minute == 0 {
            return "\(hour)\(period)"
        } else {
            let formattedMinute = String(format: "%02d", minute)
            return "\(hour):\(formattedMinute)\(period)"
        }
    }
    
    static func formatDateToRelativeTime(
        _ date: Date,
        includeAgo: Bool = true
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.second, .minute, .hour, .day, .month, .year]
        let seconds = abs(date.timeIntervalSinceNow)

        let formattedRelativeTime = formatter.string(from: seconds) ?? ""

        if !formattedRelativeTime.isEmpty && includeAgo {
            return "\(formattedRelativeTime) ago"
        } else {
            return formattedRelativeTime
        }
    }

    /// Formats `date` to "Today", "Yesterday", "2d ago" through "6d ago", "1w ago", then absolute dates.
    @MainActor
    static func formatDateToRelativeDay(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)

        guard let dayDifference = calendar.dateComponents(
            [.day],
            from: startOfDate,
            to: startOfToday
        ).day
        else {
            return formatAsAbsoluteDate(date)
        }

        switch dayDifference {
        case 0:
            return String.localized("Today")
        case 1:
            return String.localized("Yesterday")
        case 2...6:
            return String.localized("%dd ago", dayDifference)
        case 7:
            return String.localized("1w ago")
        default:
            return formatAsAbsoluteDate(date)
        }
    }

    private static let absoluteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "MMM d, yyyy"
        
        return formatter
    }()

    private static func formatAsAbsoluteDate(_ date: Date) -> String {
        return absoluteDateFormatter.string(from: date)
    }
}

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
