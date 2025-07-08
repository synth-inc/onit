//
//  TooltipView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/30/24.
//

import KeyboardShortcuts
import SwiftUI

struct TooltipViewTruncated {
    var maxWidth: CGFloat
    var lineLimit: Int? = nil
}

struct TooltipView: View {
    var tooltip: Tooltip
    var truncated: TooltipViewTruncated? = nil

    var body: some View {
        if let truncated = truncated {
            content(
                truncatedText(truncated)
            )
            .fixedSize(horizontal: false, vertical: true)
        } else {
            content(
                fixedText
            )
            .frame(minHeight: 78)
        }
    }
    
    // MARK: - Child Components
    
    var text: some View {
        Text(tooltip.prompt.split(separator: "\n")[0])
            .styleText(size: 12)
            .padding(.vertical, 8)
    }
    
    var fixedText: some View {
        text.fixedSize()
    }
    
    func truncatedText(_ truncated: TooltipViewTruncated) -> some View {
        text
            .lineLimit(truncated.lineLimit ?? 6)
            .truncationMode(.tail)
            .frame(
                maxWidth: truncated.maxWidth,
                alignment: .leading
            )
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
    
    func content(_ textView: some View) -> some View {
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
}

#Preview {
    TooltipView(tooltip: .sample)
}
