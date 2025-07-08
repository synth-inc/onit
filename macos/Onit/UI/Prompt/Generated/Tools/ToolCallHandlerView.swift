//
//  ToolCallHandlerView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import SwiftUI

struct ToolCallHandlerView: View {
    let response: Response
    
    var body: some View {
        Group {
            if let functionName = response.toolCallFunctionName, !functionName.isEmpty {
                toolView(for: functionName)
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func toolView(for functionName: String) -> some View {
        let nameParts = functionName.split(separator: "_")
        
        if nameParts.count >= 2 {
            let appName = String(nameParts[0])
            
            switch appName {
            case "diff":
                DiffToolView(response: response)
            default:
                ToolCallView(response: response)
            }
        } else {
            ToolCallView(response: response)
        }
    }
}

// MARK: - Tool-specific Views

struct CalendarToolView: View {
    let response: Response
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Calendar Event")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            if let result = response.toolCallResult {
                Text(result)
                    .font(.body)
                    .foregroundColor(.primary)
            } else if response.toolCallSuccess == false {
                Text("Failed to create calendar event")
                    .font(.body)
                    .foregroundColor(.red)
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Creating calendar event...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}
