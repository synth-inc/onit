//
//  FeatureDisableManager+SchedulingTimeRange.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Foundation

extension FeatureDisableManager {
    // MARK: - Helper Functions

    private func determineNextClosestTimeRangeDate(timeRange: DisableRuleTimeRange) -> Date? {
        let calendar = Calendar.current

        let startTimeHour = calendar.component(.hour, from: timeRange.startTime)
        let startTimeMinute = calendar.component(.minute, from: timeRange.startTime)

        let endTimeHour = calendar.component(.hour, from: timeRange.endTime)
        let endTimeMinute = calendar.component(.minute, from: timeRange.endTime)

        let startDate = DateComponents(hour: startTimeHour, minute: startTimeMinute)
        let endDate = DateComponents(hour: endTimeHour, minute: endTimeMinute)

        let now = Date()

        let closestDateFromStartDate = calendar.nextDate(
            after: now,
            matching: startDate,
            matchingPolicy: .nextTime,
            direction: .forward
        )

        let closestDateFromEndDate = calendar.nextDate(
            after: now,
            matching: endDate,
            matchingPolicy: .nextTime,
            direction: .forward
        )

        return [closestDateFromStartDate, closestDateFromEndDate].compactMap { $0 }.min()
    }

    // MARK: - Time Range Date Helpers

    func getNextClosestTimeRangeDate() -> Date? {
        let timeRangeBoundaries: [Date] = self.featureDisableRules.compactMap { disableRule in
            guard let timeRange = disableRule.timeRange else { return nil }
            return self.determineNextClosestTimeRangeDate(timeRange: timeRange)
        }

        return timeRangeBoundaries.min()
    }

    // MARK: - Time Range Check

    func checkIsWithinDisabledTimeRange(_ timeRange: DisableRuleTimeRange) -> Bool {
        let calendar = Calendar.current

        let startTimeHour = calendar.component(.hour, from: timeRange.startTime)
        let startTimeMinute = calendar.component(.minute, from: timeRange.startTime)

        let endTimeHour = calendar.component(.hour, from: timeRange.endTime)
        let endTimeMinute = calendar.component(.minute, from: timeRange.endTime)

        let now = Date()

        guard let startDate = calendar.date(bySettingHour: startTimeHour, minute: startTimeMinute, second: 0, of: now),
              let endDate = calendar.date(bySettingHour: endTimeHour, minute: endTimeMinute, second: 0, of: now)
        else { return false }

        // Same-day window
        if startDate <= endDate {
            let isCurrentlyWithinStartAndEndDates = DateInterval(start: startDate, end: endDate).contains(now)
            return isCurrentlyWithinStartAndEndDates
        }
        // Overnight window
        else {
            guard let endDateAsNextDay = calendar.date(byAdding: .day, value: 1, to: endDate),
                  let startDateAsPreviousDay = calendar.date(byAdding: .day, value: -1, to: startDate)
            else { return false }

            // e.g. If `now` = 23:30, `startTime` = 22:00, and `endTime` = 2:00
            let isCurrentlyBeforeMidnight = DateInterval(start: startDate, end: endDateAsNextDay).contains(now)

            // e.g. if `now` = 1:00, `startTime` = 22:00, and `endTime` = 2:00
            let isCurrentlyAfterMidnight = DateInterval(start: startDateAsPreviousDay, end: endDate).contains(now)

            return isCurrentlyBeforeMidnight || isCurrentlyAfterMidnight
        }
    }
}
