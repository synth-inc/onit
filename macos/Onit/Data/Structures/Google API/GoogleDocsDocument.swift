//
//  GoogleDocsDocument.swift
//  Onit
//
//  Created by Kévin Naudin on 07/09/2025.
//

import Foundation

struct GoogleDocsDocument {
    let documentId: String
    let title: String
    let body: GoogleDocsBody
    let revisionId: String
}

struct GoogleDocsBody {
    let content: [GoogleDocsStructuralElement]
}

struct GoogleDocsStructuralElement {
    let startIndex: Int?
    let endIndex: Int?
    let paragraph: GoogleDocsParagraph?
    let table: GoogleDocsTable?
    let pageBreak: GoogleDocsPageBreak?
}

struct GoogleDocsParagraph {
    let elements: [GoogleDocsParagraphElement]
}

struct GoogleDocsParagraphElement {
    let startIndex: Int?
    let endIndex: Int?
    let textRun: GoogleDocsTextRun?
}

struct GoogleDocsTextRun {
    let content: String
}

struct GoogleDocsTable {
    let rows: Int
    let columns: Int
    let tableRows: [GoogleDocsTableRow]
}

struct GoogleDocsTableRow {
    let tableCells: [GoogleDocsTableCell]
}

struct GoogleDocsTableCell {
    let content: [GoogleDocsStructuralElement]
}

struct GoogleDocsPageBreak {
    // Page break doesn't have additional properties
}
