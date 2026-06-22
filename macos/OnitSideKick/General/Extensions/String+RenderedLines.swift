//
//  String+RenderedLines.swift
//  Onit
//
//  Created by Kévin Naudin on 2026-04-28.
//

import AppKit
import Foundation

extension String {
    /// Returns the number of visible lines this string would render to inside a
    /// container of `width` points using `font`, replicating AppKit's text
    /// wrapping. Used to drive See more / See less affordances accurately —
    /// character-count heuristics misjudge proportional-font wrapping too
    /// often to be useful.
    func numberOfRenderedLines(font: NSFont, width: CGFloat) -> Int {
        guard !isEmpty, width > 0 else { return 0 }

        let textStorage = NSTextStorage(string: self)
        textStorage.addAttributes(
            [.font: font],
            range: NSRange(location: 0, length: textStorage.length)
        )

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        // Force layout so glyph counts are accurate before walking line fragments.
        layoutManager.glyphRange(for: textContainer)

        var lineCount = 0
        var index = 0
        let glyphCount = layoutManager.numberOfGlyphs

        while index < glyphCount {
            var lineRange = NSRange()
            _ = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            lineCount += 1
        }

        return lineCount
    }
}
