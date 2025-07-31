//
//  ToolCallView.swift
//  Onit
//
//  Created by Jay Swanson on 6/13/25.
//

import Foundation
import SwiftUI

struct ToolCallView: View {
    let response: Response
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if response.hasToolCall {
                toolCallHeader

                if isExpanded {
                    toolCallDetails
                }
            }
        }
        .background(Color.clear)
        .cornerRadius(8)
    }

    private var toolCallHeader: some View {
        HStack(spacing: 10) {
            // Calendar icon
            Image(systemName: "calendar")
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.red)
                .cornerRadius(6)

            // Tool name
            Text(displayToolName)
                .foregroundColor(.primary)
                .font(.system(size: 15, weight: .medium))

            Spacer()

            // Success/Error indicator
            if let success = response.toolCallSuccess {
                Image(systemName: success ? "checkmark" : "xmark")
                    .foregroundColor(success ? .green : .red)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle().fill(success ? Color.green.opacity(0.1) : Color.red.opacity(0.1)))
            }

            // Expand/Collapse arrow (only show when expandable)
            if hasExpandableContent {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12, weight: .medium))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.separatorColor).opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            if hasExpandableContent {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    private var toolCallDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input section
            if let arguments = response.toolCallArguments,
                !arguments.isEmpty
            {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(parsedArguments, id: \.key) { argument in
                            HStack(alignment: .top) {
                                Text("\(argument.key):")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 80, alignment: .leading)

                                Text(argument.value)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                        }
                    }
                }
            }

            // Output section
            if let result = response.toolCallResult,
                !result.isEmpty
            {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    Text(result)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(NSColor.separatorColor).opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.1), lineWidth: 1)
        )
        .padding(.top, 6)
    }

    private var hasExpandableContent: Bool {
        let hasArguments = response.toolCallArguments != nil && !response.toolCallArguments!.isEmpty
        let hasResult = response.toolCallResult != nil && !response.toolCallResult!.isEmpty
        return hasArguments || hasResult
    }

    private var displayToolName: String {
        guard let toolName = response.toolCallName else {
            return "Tool Call"
        }

        // Convert tool name to display name
        let parts = toolName.split(separator: "_")
        if parts.count >= 2 {
            let toolName = parts[1...].joined(separator: " ")
            return toolName.capitalized.replacingOccurrences(of: "_", with: " ")
        }

        return toolName.capitalized.replacingOccurrences(of: "_", with: " ")
    }

    private var parsedArguments: [(key: String, value: String)] {
        guard let arguments = response.toolCallArguments else { return [] }

        do {
            if let data = arguments.data(using: .utf8),
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            {

                return json.compactMap { key, value in
                    let displayKey = key.replacingOccurrences(of: "_", with: " ").capitalized
                    let displayValue: String

                    if let stringValue = value as? String {
                        // Format dates if they look like ISO dates
                        if stringValue.contains("T") && stringValue.contains(":") {
                            if let date = ISO8601DateFormatter().date(from: stringValue) {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .medium
                                formatter.timeStyle = .short
                                displayValue = formatter.string(from: date)
                            } else {
                                displayValue = stringValue
                            }
                        } else {
                            displayValue = stringValue
                        }
                    } else {
                        displayValue = String(describing: value)
                    }

                    return (key: displayKey, value: displayValue)
                }
            }
        } catch {
            print("Error parsing tool arguments: \(error)")
        }

        return []
    }
}
