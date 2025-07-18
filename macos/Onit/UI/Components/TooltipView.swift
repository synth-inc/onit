//
//  TooltipView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/30/24.
//

import KeyboardShortcuts
import SwiftUI

struct TooltipConfig {
    var maxWidth: CGFloat
}

struct TooltipView: View {
    var tooltip: Tooltip
    var config: TooltipConfig? = nil
    
    private var text: String {
        let trimmedTooltipText = tooltip.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let textSubstrings: [String] = trimmedTooltipText.components(separatedBy: CharacterSet.newlines)
        let textSubstringsCount = textSubstrings.count
        
        if textSubstringsCount > 1 {
            let maxIndex = textSubstringsCount > 4 ? 4 : textSubstringsCount
            var trimmedTextSubstrings = textSubstrings[0..<maxIndex].joined(separator: "\n")
            
            if trimmedTextSubstrings.count > 200 {
                trimmedTextSubstrings = String(trimmedTextSubstrings.prefix(200)) + "..."
            }
            
            if textSubstringsCount > 4 {
                trimmedTextSubstrings += "\n..."
            }
            
            return trimmedTextSubstrings
        } else {
            return trimmedTooltipText
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if let config = config {
                textView
                    .frame(
                        maxWidth: config.maxWidth,
                        alignment: .leading
                    )
            } else {
                textView
            }

            Group {
                switch tooltip.shortcut {

                case .keyboardShortcuts(let name):
                    if let shortcut = KeyboardShortcuts.getShortcut(for: name) {
                        KeyboardShortcutView(shortcut: shortcut.native)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .background(.gray400, in: .rect(cornerRadius: 6))
                            .padding(4)
                            .fixedSize()
                    }
                case .none:
                    Spacer()
                        .frame(width: 8)
                }
            }
            .appFont(.medium10)
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .background {
            tooltipBackground
        }
        .frame(minHeight: 78)
    }
    
    var textView: some View {
        Text(text)
            .appFont(.medium12)
            .padding(.vertical, 8)
    }
    
    var tooltipBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray500)
        //            .shadow(color: .black.opacity(0.36), radius: 2.5, x: 0, y: 0)
    }
}

#Preview {
    TooltipView(tooltip: .sample)
}
