//
//  CalendarTool.swift
//  Onit
//
//  Created by Jay Swanson on 6/12/25.
//

import EventKit
import Foundation

class CalendarTool: ToolProtocol {
    
    let availableTools: [String: Tool] = [
        "create_event": Tool(
            name: "calendar_create_event",
            description: "Create a new calendar event",
            parameters: ToolParameters(
                properties: [
                    "title": ToolProperty(
                        type: "string",
                        description: "Title of the event",
                        items: nil
                    ),
                    "start_date": ToolProperty(
                        type: "string",
                        description: "Start date and time in ISO 8601 format (YYYY-MM-DDTHH:MM:SS)",
                        items: nil
                    ),
                    "end_date": ToolProperty(
                        type: "string",
                        description: "End date and time in ISO 8601 format (YYYY-MM-DDTHH:MM:SS)",
                        items: nil
                    ),
                    "location": ToolProperty(
                        type: "string",
                        description: "Optional location of the event",
                        items: nil
                    ),
                    "notes": ToolProperty(
                        type: "string",
                        description: "Optional notes or description for the event",
                        items: nil
                    ),
                    "calendar_name": ToolProperty(
                        type: "string",
                        description: "Optional name of the calendar to create the event in",
                        items: nil
                    ),
                    "is_all_day": ToolProperty(
                        type: "boolean",
                        description: "Optional flag to create an all-day event",
                        items: nil
                    ),
                ],
                required: ["title", "start_date", "end_date"]
            )
        )
    ]

    var selectedTools: [String] = ["create_event"]

    var activeTools: [Tool] {
        return availableTools
            .compactMap { selectedTools.contains($0.key) ? $0.value : nil }
    }
    
    func canExecute(partialArguments: String) -> Bool {
        false
    }

    func execute(toolName: String, arguments: String) async -> Result<ToolCallResult, ToolCallError> {
        switch toolName {
        case "create_event":
            return await createCalendarEvent(toolName: toolName, arguments: arguments)
        default:
            return .failure(
                ToolCallError(
                    toolName: toolName, message: "Unsupported tool name"))
        }
    }

    struct CreateCalendarEventArguments: Codable {
        let title: String
        let start_date: String
        let end_date: String
        let location: String?
        let notes: String?
        let calendar_name: String?
        let is_all_day: Bool?
    }

    func createCalendarEvent(toolName: String, arguments: String) async -> Result<ToolCallResult, ToolCallError> {
        do {
            // Parse arguments
            guard let data = arguments.data(using: .utf8) else {
                return .failure(
                    ToolCallError(
                        toolName: toolName, message: "Failed to parse arguments"))
            }

            let args = try JSONDecoder().decode(CreateCalendarEventArguments.self, from: data)

            // Request calendar access
            let eventStore = EKEventStore()

            // Check authorization status
            let authStatus = EKEventStore.authorizationStatus(for: .event)

            switch authStatus {
            case .notDetermined:
                // Request access
                let granted = try await eventStore.requestFullAccessToEvents()
                if !granted {
                    return .failure(
                        ToolCallError(
                            toolName: toolName,
                            message:
                                "Calendar access was denied. Please grant calendar access in System Preferences."
                        ))
                }
            case .denied, .restricted:
                return .failure(
                    ToolCallError(
                        toolName: toolName,
                        message:
                            "Calendar access is denied. Please grant calendar access in System Preferences."
                    ))
            case .fullAccess, .writeOnly:
                // We have access, continue
                break
            @unknown default:
                break
            }

            // Parse dates
            let dateFormatter = ISO8601DateFormatter()
            // Try with timezone first (full ISO8601)
            dateFormatter.formatOptions = [.withInternetDateTime]

            // Try parsing with timezone first, then without timezone (assuming local time)
            var startDate: Date?
            var endDate: Date?

            startDate = dateFormatter.date(from: args.start_date)
            endDate = dateFormatter.date(from: args.end_date)

            // If parsing failed, try without timezone (assume local time)
            if startDate == nil || endDate == nil {
                let localFormatter = DateFormatter()
                localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                localFormatter.timeZone = TimeZone.current

                startDate = localFormatter.date(from: args.start_date)
                endDate = localFormatter.date(from: args.end_date)
            }

            guard let startDate = startDate, let endDate = endDate else {
                return .failure(
                    ToolCallError(
                        toolName: toolName,
                        message:
                            "Invalid date format. Please use ISO 8601 format (YYYY-MM-DDTHH:MM:SS) or (YYYY-MM-DDTHH:MM:SSZ)."
                    ))
            }

            // Find the calendar to create the event in
            let calendar: EKCalendar
            if let calendarName = args.calendar_name {
                // Find calendar by name
                if let foundCalendar = eventStore.calendars(for: .event).first(where: {
                    $0.title == calendarName
                }) {
                    calendar = foundCalendar
                } else {
                    return .failure(
                        ToolCallError(
                            toolName: toolName,
                            message: "Calendar named '\(calendarName)' not found."))
                }
            } else {
                // Use the default calendar
                guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
                    return .failure(
                        ToolCallError(
                            toolName: toolName,
                            message: "No default calendar available."))
                }
                calendar = defaultCalendar
            }

            // Create the event
            let event = EKEvent(eventStore: eventStore)
            event.title = args.title
            event.startDate = startDate
            event.endDate = endDate
            event.calendar = calendar
            event.isAllDay = args.is_all_day ?? false

            if let location = args.location {
                event.location = location
            }

            if let notes = args.notes {
                event.notes = notes
            }

            // Save the event
            try eventStore.save(event, span: .thisEvent)

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short

            var resultMessage = "Successfully created event '\(args.title)'"

            if event.isAllDay {
                resultMessage += " (All day)"
            } else {
                resultMessage +=
                    " from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))"
            }

            if let location = args.location {
                resultMessage += " at \(location)"
            }

            resultMessage += " in calendar '\(calendar.title)'"

            return .success(ToolCallResult(toolName: toolName, result: resultMessage))
        } catch {
            return .failure(
                ToolCallError(
                    toolName: toolName,
                    message: "Error creating calendar event: \(error.localizedDescription)"))
        }
    }
}
