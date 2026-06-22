//
//  String+LeadingBoundarySignature.swift
//  Onit
//
//  Captures the structural prefix of a string for "did the user change the leading boundary?"
//  comparisons. Two strings with the same `leadingBoundarySignature` have indistinguishable
//  boundary semantics for cleanup-pipeline decisions that depend on leading content
//  (Capitalization, TrailingPunctScorer, etc.). Used by the correction-overlay flow to decide
//  whether the cleanup's preceding-char-consume decision is still valid against the user's
//  edited `correctionText`.
//

import Foundation

extension String {
    /// Leading whitespace + first non-whitespace character, case-sensitive.
    ///
    /// Examples:
    ///   "world"      → "w"
    ///   "World"      → "W"
    ///   " hello"     → " h"
    ///   "  Hello"    → "  H"
    ///   ". hello"    → "."
    ///   ""           → ""
    ///   "   "        → "   "   (all-whitespace: signature is the whole string)
    var leadingBoundarySignature: String {
        var idx = startIndex
        while idx < endIndex, self[idx].isWhitespace {
            idx = index(after: idx)
        }
        if idx < endIndex {
            idx = index(after: idx)
        }
        return String(self[startIndex..<idx])
    }
}
