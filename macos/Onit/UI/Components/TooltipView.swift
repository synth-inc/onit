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
    var lineLimit: Int? = nil
}

struct TooltipView: View {
    var tooltip: Tooltip
    var config: TooltipConfig? = nil

    var body: some View {
        if let config = config {
            truncatedTextView(config)
        } else {
            fixedTextView
        }
    }
    
    // MARK: - Child Components
    
    private func findValidSubstring(_ substrings: [String]) -> String {
        return substrings
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces)
        ?? ""
    }
    @ViewBuilder
    var textView: some View {
        let newlineCharacters = CharacterSet.newlines
        let textSubstrings: [String] = tooltip.prompt.components(separatedBy: newlineCharacters)
        let textFirstLine: String = findValidSubstring(textSubstrings)
        
        let hasMultipleLines = textSubstrings.count > 1
        
        if hasMultipleLines {
            VStack(alignment: .leading) {
                Text(textFirstLine)
                Text("...")
            }
            .padding(.vertical, 8)
            .styleText(size: 12)
        } else {
            Text(textFirstLine)
                .padding(.vertical, 8)
                .styleText(size: 12)
        }
    }
    
    func textWithShortcutWrapper(_ textView: some View) -> some View {
        HStack(spacing: 0) {
            textView
            tooltipShortcut
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .background {
            tooltipBackground
        }
    }
    
    var fixedTextView: some View {
        textWithShortcutWrapper(
            textView
                .fixedSize()
        )
        .frame(minHeight: 78)
    }
    
    func truncatedTextView(_ config: TooltipConfig) -> some View {
        textWithShortcutWrapper(
            textView
                .truncateText(lineLimit: config.lineLimit ?? 6)
                .frame(
                    maxWidth: config.maxWidth,
                    alignment: .leading
                )
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var tooltipShortcut: some View {
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
    
    var tooltipBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray500)
        //            .shadow(color: .black.opacity(0.36), radius: 2.5, x: 0, y: 0)
    }
}

#Preview {
    TooltipView(tooltip: .sample)
}
