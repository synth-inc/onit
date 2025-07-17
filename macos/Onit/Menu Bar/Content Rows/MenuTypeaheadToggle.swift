//
//  MenuTypeaheadToggle.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import SwiftUI
import Defaults

struct MenuTypeaheadToggle: View {
    @Default(.collectTypeaheadTestCases) var collectTypeaheadTestCases
    
    var body: some View {
        MenuBarRow {
            // Toggle the setting
            collectTypeaheadTestCases.toggle()
        } leading: {
            HStack(spacing: 8) {
                // Recording indicator dot
                Circle()
                    .fill(collectTypeaheadTestCases ? .green : .yellow)
                    .frame(width: 8, height: 8)
                
                Text(collectTypeaheadTestCases ? "Stop Recording Typeahead" : "Start Recording Typeahead")
            }
            .padding(.leading, 10)
        }
    }
}

#Preview {
    MenuTypeaheadToggle()
} 