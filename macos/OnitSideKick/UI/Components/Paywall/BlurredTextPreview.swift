//
//  BlurredTextPreview.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

import SwiftUI

/// A reusable component for displaying blurred text content.
struct BlurredTextPreview: View {
    
    let text: String
    var blurRadius: CGFloat? = nil  // If nil, auto-calculated from fontSize
    var opacity: Double = 1.0
    var lineLimit: Int? = nil
    var fontSize: CGFloat = 13

    /// Blur radius adapted to font size (40% of the font size)
    private var effectiveBlurRadius: CGFloat {
        blurRadius ?? (fontSize * 0.4)
    }

    var body: some View {
        Text(text)
            .styleText(size: fontSize, weight: .regular, color: Color.S_0)
            .lineLimit(lineLimit)
            .blur(radius: effectiveBlurRadius)
            .opacity(opacity)
    }
}
