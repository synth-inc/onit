//
//  GoogleDocsOperations.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation

enum GoogleDocsOperation {
    case insertText(index: Int, text: String)
    case deleteContentRange(startIndex: Int, endIndex: Int)
    case replaceText(startIndex: Int, endIndex: Int, newText: String)
}
