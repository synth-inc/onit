//
//  GoogleDocsParser.swift
//  Onit
//
//  Created by Kévin Naudin on 07/11/2025.
//

import Foundation

class GoogleDocsParser {
    func parseGoogleDocsDocument(from data: [String: Any]) throws -> GoogleDocsDocument {
        guard let documentId = data["documentId"] as? String,
              let title = data["title"] as? String,
              let bodyData = data["body"] as? [String: Any],
              let revisionId = data["revisionId"] as? String else {
            throw GoogleDriveError.invalidResponse("Invalid Google Docs document structure")
        }
        
        let body = try parseGoogleDocsBody(from: bodyData)
        
        return GoogleDocsDocument(
            documentId: documentId,
            title: title,
            body: body,
            revisionId: revisionId
        )
    }
    
    private func parseGoogleDocsBody(from data: [String: Any]) throws -> GoogleDocsBody {
        guard let contentArray = data["content"] as? [[String: Any]] else {
            throw GoogleDriveError.invalidResponse("Invalid Google Docs body structure")
        }
        
        let content = contentArray.compactMap { elementData in
            return parseGoogleDocsStructuralElement(from: elementData)
        }
        
        return GoogleDocsBody(content: content)
    }
    
    private func parseGoogleDocsStructuralElement(from data: [String: Any]) -> GoogleDocsStructuralElement? {
        let startIndex = data["startIndex"] as? Int
        let endIndex = data["endIndex"] as? Int
        
        var paragraph: GoogleDocsParagraph?
        var table: GoogleDocsTable?
        var pageBreak: GoogleDocsPageBreak?
        var sectionBreak: GoogleDocsSectionBreak?
        var tableOfContents: GoogleDocsTableOfContents?
        
        if let paragraphData = data["paragraph"] as? [String: Any] {
            paragraph = parseGoogleDocsParagraph(from: paragraphData)
        }
        
        if let tableData = data["table"] as? [String: Any] {
            table = parseGoogleDocsTable(from: tableData)
        }
        
        if data["pageBreak"] != nil {
            pageBreak = GoogleDocsPageBreak()
        }
        
        if let sectionBreakData = data["sectionBreak"] as? [String: Any] {
            sectionBreak = parseGoogleDocsSectionBreak(from: sectionBreakData)
        }
        
        if let tableOfContentsData = data["tableOfContents"] as? [String: Any] {
            tableOfContents = parseGoogleDocsTableOfContents(from: tableOfContentsData)
        }
        
        return GoogleDocsStructuralElement(
            startIndex: startIndex,
            endIndex: endIndex,
            paragraph: paragraph,
            table: table,
            pageBreak: pageBreak,
            sectionBreak: sectionBreak,
            tableOfContents: tableOfContents
        )
    }
    
    private func parseGoogleDocsParagraphElement(from data: [String: Any]) -> GoogleDocsParagraphElement? {
        let startIndex = data["startIndex"] as? Int
        let endIndex = data["endIndex"] as? Int
        
        var textRun: GoogleDocsTextRun?
        var inlineObjectElement: GoogleDocsInlineObjectElement?
        var autoText: GoogleDocsAutoText?
        var columnBreak: GoogleDocsColumnBreak?
        var footnoteReference: GoogleDocsFootnoteReference?
        var horizontalRule: GoogleDocsHorizontalRule?
        var equation: GoogleDocsEquation?
        var person: GoogleDocsPerson?
        var richLink: GoogleDocsRichLink?
        
        if let textRunData = data["textRun"] as? [String: Any],
           let content = textRunData["content"] as? String {
            textRun = GoogleDocsTextRun(content: content)
        }
        
        if let inlineObjectData = data["inlineObjectElement"] as? [String: Any] {
            let inlineObjectId = inlineObjectData["inlineObjectId"] as? String
            inlineObjectElement = GoogleDocsInlineObjectElement(inlineObjectId: inlineObjectId)
        }
        
        if let autoTextData = data["autoText"] as? [String: Any] {
            let type = autoTextData["type"] as? String
            autoText = GoogleDocsAutoText(type: type)
        }
        
        if data["columnBreak"] != nil {
            columnBreak = GoogleDocsColumnBreak()
        }
        
        if let footnoteRefData = data["footnoteReference"] as? [String: Any] {
            let footnoteId = footnoteRefData["footnoteId"] as? String
            footnoteReference = GoogleDocsFootnoteReference(footnoteId: footnoteId)
        }
        
        if data["horizontalRule"] != nil {
            horizontalRule = GoogleDocsHorizontalRule()
        }
        
        if data["equation"] != nil {
            equation = GoogleDocsEquation()
        }
        
        if let personData = data["person"] as? [String: Any] {
            let personId = personData["personId"] as? String
            var personProperties: GoogleDocsPersonProperties?
            if let personPropsData = personData["personProperties"] as? [String: Any] {
                let name = personPropsData["name"] as? String
                let email = personPropsData["email"] as? String
                personProperties = GoogleDocsPersonProperties(name: name, email: email)
            }
            person = GoogleDocsPerson(personId: personId, personProperties: personProperties)
        }
        
        if let richLinkData = data["richLink"] as? [String: Any] {
            let richLinkId = richLinkData["richLinkId"] as? String
            var richLinkProperties: GoogleDocsRichLinkProperties?
            if let richLinkPropsData = richLinkData["richLinkProperties"] as? [String: Any] {
                let title = richLinkPropsData["title"] as? String
                let mimeType = richLinkPropsData["mimeType"] as? String
                richLinkProperties = GoogleDocsRichLinkProperties(title: title, mimeType: mimeType)
            }
            richLink = GoogleDocsRichLink(richLinkId: richLinkId, richLinkProperties: richLinkProperties)
        }
        
        if textRun == nil && inlineObjectElement == nil && autoText == nil && columnBreak == nil && 
           footnoteReference == nil && horizontalRule == nil && equation == nil && person == nil && richLink == nil {
            return nil
        }
        
        return GoogleDocsParagraphElement(
            startIndex: startIndex,
            endIndex: endIndex,
            textRun: textRun,
            inlineObjectElement: inlineObjectElement,
            autoText: autoText,
            columnBreak: columnBreak,
            footnoteReference: footnoteReference,
            horizontalRule: horizontalRule,
            equation: equation,
            person: person,
            richLink: richLink
        )
    }
    
    private func parseGoogleDocsParagraph(from data: [String: Any]) -> GoogleDocsParagraph? {
        guard let elementsArray = data["elements"] as? [[String: Any]] else {
            return nil
        }
        
        let elements = elementsArray.compactMap { elementData in
            return parseGoogleDocsParagraphElement(from: elementData)
        }
        
        return GoogleDocsParagraph(elements: elements)
    }
    
    private func parseGoogleDocsTable(from data: [String: Any]) -> GoogleDocsTable? {
        let rows = data["rows"] as? Int ?? 0
        let columns = data["columns"] as? Int ?? 0
        
        var tableRows: [GoogleDocsTableRow] = []
        if let tableRowsData = data["tableRows"] as? [[String: Any]] {
            tableRows = tableRowsData.compactMap { parseGoogleDocsTableRow(from: $0) }
        }
        
        return GoogleDocsTable(
            rows: rows,
            columns: columns,
            tableRows: tableRows
        )
    }
    
    private func parseGoogleDocsTableRow(from data: [String: Any]) -> GoogleDocsTableRow? {
        var tableCells: [GoogleDocsTableCell] = []
        if let tableCellsData = data["tableCells"] as? [[String: Any]] {
            tableCells = tableCellsData.compactMap { parseGoogleDocsTableCell(from: $0) }
        }
        
        return GoogleDocsTableRow(tableCells: tableCells)
    }
    
    private func parseGoogleDocsTableCell(from data: [String: Any]) -> GoogleDocsTableCell? {
        var content: [GoogleDocsStructuralElement] = []
        if let contentData = data["content"] as? [[String: Any]] {
            content = contentData.compactMap { parseGoogleDocsStructuralElement(from: $0) }
        }
        
        return GoogleDocsTableCell(content: content)
    }
    
    private func parseGoogleDocsSectionBreak(from data: [String: Any]) -> GoogleDocsSectionBreak? {
        var sectionStyle: GoogleDocsSectionStyle?
        if let sectionStyleData = data["sectionStyle"] as? [String: Any] {
            let columnSeparatorStyle = sectionStyleData["columnSeparatorStyle"] as? String
            let contentDirection = sectionStyleData["contentDirection"] as? String
            let sectionType = sectionStyleData["sectionType"] as? String
            sectionStyle = GoogleDocsSectionStyle(
                columnSeparatorStyle: columnSeparatorStyle,
                contentDirection: contentDirection,
                sectionType: sectionType
            )
        }
        
        return GoogleDocsSectionBreak(sectionStyle: sectionStyle)
    }
    
    private func parseGoogleDocsTableOfContents(from data: [String: Any]) -> GoogleDocsTableOfContents? {
        var content: [GoogleDocsStructuralElement] = []
        if let contentData = data["content"] as? [[String: Any]] {
            content = contentData.compactMap { parseGoogleDocsStructuralElement(from: $0) }
        }
        
        return GoogleDocsTableOfContents(content: content)
    }
}
