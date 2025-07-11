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
    let sectionBreak: GoogleDocsSectionBreak?
    let tableOfContents: GoogleDocsTableOfContents?
}

struct GoogleDocsParagraph {
    let elements: [GoogleDocsParagraphElement]
}

struct GoogleDocsParagraphElement {
    let startIndex: Int?
    let endIndex: Int?
    let textRun: GoogleDocsTextRun?
    let inlineObjectElement: GoogleDocsInlineObjectElement?
    let autoText: GoogleDocsAutoText?
    let columnBreak: GoogleDocsColumnBreak?
    let footnoteReference: GoogleDocsFootnoteReference?
    let horizontalRule: GoogleDocsHorizontalRule?
    let equation: GoogleDocsEquation?
    let person: GoogleDocsPerson?
    let richLink: GoogleDocsRichLink?
}

struct GoogleDocsTextRun {
    let content: String
}

struct GoogleDocsInlineObjectElement {
    let inlineObjectId: String?
}

struct GoogleDocsAutoText {
    let type: String?
}

struct GoogleDocsColumnBreak {
    // Column break has no specific properties
}

struct GoogleDocsFootnoteReference {
    let footnoteId: String?
}

struct GoogleDocsHorizontalRule {
    // Horizontal rule has no specific properties
}

struct GoogleDocsEquation {
    // Equation content - simplified for now
}

struct GoogleDocsPerson {
    let personId: String?
    let personProperties: GoogleDocsPersonProperties?
}

struct GoogleDocsPersonProperties {
    let name: String?
    let email: String?
}

struct GoogleDocsRichLink {
    let richLinkId: String?
    let richLinkProperties: GoogleDocsRichLinkProperties?
}

struct GoogleDocsRichLinkProperties {
    let title: String?
    let mimeType: String?
}

struct GoogleDocsSectionBreak {
    let sectionStyle: GoogleDocsSectionStyle?
}

struct GoogleDocsSectionStyle {
    let columnSeparatorStyle: String?
    let contentDirection: String?
    let sectionType: String?
}

struct GoogleDocsTableOfContents {
    let content: [GoogleDocsStructuralElement]
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
