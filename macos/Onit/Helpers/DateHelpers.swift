//
//  DateHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import Foundation

func convertEpochDateToCleanDate(
    epochDate: Double,
    dateStyle: DateFormatter.Style = DateFormatter.Style.medium,
    timeStyle: DateFormatter.Style = DateFormatter.Style.none
) -> String {
    let date = Date(timeIntervalSince1970: epochDate)

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = dateStyle
    dateFormatter.timeStyle = timeStyle

    let cleanDate = dateFormatter.string(from: date)
    return cleanDate
}

func getTodayAsEpochDate() -> Double {
    let today = Date()
    let todayAsEpochDate = today.timeIntervalSince1970
    return todayAsEpochDate
}
