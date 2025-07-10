//
//  GoogleSlidesOperations.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation

enum GoogleSlidesOperation {
    case insertText(objectId: String, insertionIndex: Int, text: String)
    case deleteText(objectId: String, textRange: GoogleSlidesRange)
    case replaceAllText(containsText: String, replaceText: String)
    case createSlide(slideLayoutReference: GoogleSlidesLayoutReference?, insertionIndex: Int?)
    case deleteSlide(slideId: String)
    case createShape(slideId: String, shapeType: String, elementProperties: GoogleSlidesPageElementProperties)
    case createTextBox(slideId: String, elementProperties: GoogleSlidesPageElementProperties)
    case createImage(slideId: String, imageUrl: String, elementProperties: GoogleSlidesPageElementProperties)
    case updateShapeProperties(objectId: String, shapeProperties: GoogleSlidesShapeProperties)
    case updateTextStyle(objectId: String, textRange: GoogleSlidesRange?, style: GoogleSlidesTextStyle)
    case updateParagraphStyle(objectId: String, textRange: GoogleSlidesRange?, style: GoogleSlidesParagraphStyle)
    case groupObjects(childrenObjectIds: [String])
    case ungroupObjects(objectIds: [String])
    case duplicateObject(objectId: String, objectIds: [String: String])
}

struct GoogleSlidesDiff {
    let fileId: String
    let presentationStructure: GoogleSlidesPresentation
    let originalText: String
    let proposedOperations: [GoogleSlidesOperation]
    let previewText: String
}

struct GoogleSlidesPresentation {
    let presentationId: String
    let pageSize: GoogleSlidesSize
    let slides: [GoogleSlidesSlide]
    let title: String
    let masters: [GoogleSlidesMaster]?
    let layouts: [GoogleSlidesLayout]?
}

struct GoogleSlidesSlide {
    let objectId: String
    let pageElements: [GoogleSlidesPageElement]?
    let slideProperties: GoogleSlidesSlideProperties?
    let notesPage: GoogleSlidesNotesPage?
}

struct GoogleSlidesPageElement {
    let objectId: String
    let size: GoogleSlidesSize?
    let transform: GoogleSlidesAffineTransform?
    let title: String?
    let description: String?
    let shape: GoogleSlidesShape?
    let image: GoogleSlidesImage?
    let video: GoogleSlidesVideo?
    let table: GoogleSlidesTable?
    let wordArt: GoogleSlidesWordArt?
    let line: GoogleSlidesLine?
    let sheetsChart: GoogleSlidesSheetsChart?
}

struct GoogleSlidesShape {
    let shapeType: String
    let text: GoogleSlidesTextContent?
    let shapeProperties: GoogleSlidesShapeProperties?
}

struct GoogleSlidesTextContent {
    let textElements: [GoogleSlidesTextElement]
    let lists: [String: GoogleSlidesList]?
}

struct GoogleSlidesTextElement {
    let endIndex: Int
    let startIndex: Int?
    let paragraphMarker: GoogleSlidesParagraphMarker?
    let textRun: GoogleSlidesTextRun?
    let autoText: GoogleSlidesAutoText?
}

struct GoogleSlidesParagraphMarker {
    let style: GoogleSlidesParagraphStyle?
    let bullet: GoogleSlidesBullet?
}

struct GoogleSlidesTextRun {
    let content: String
    let style: GoogleSlidesTextStyle?
}

struct GoogleSlidesAutoText {
    let type: String
    let content: String?
}

struct GoogleSlidesTextStyle {
    let backgroundColor: GoogleSlidesOptionalColor?
    let foregroundColor: GoogleSlidesOptionalColor?
    let bold: Bool?
    let italic: Bool?
    let fontFamily: String?
    let fontSize: GoogleSlidesSize?
    let link: GoogleSlidesLink?
    let underline: Bool?
    let strikethrough: Bool?
    let smallCaps: Bool?
    let fontWeight: Int?
    let baselineOffset: String?
}

struct GoogleSlidesParagraphStyle {
    let lineSpacing: Double?
    let alignment: String?
    let indentStart: GoogleSlidesSize?
    let indentEnd: GoogleSlidesSize?
    let spaceAbove: GoogleSlidesSize?
    let spaceBelow: GoogleSlidesSize?
    let indentFirstLine: GoogleSlidesSize?
    let direction: String?
    let spacingMode: String?
}

struct GoogleSlidesBullet {
    let listId: String?
    let nestingLevel: Int?
    let glyph: String?
    let bulletStyle: GoogleSlidesTextStyle?
}

struct GoogleSlidesList {
    let listId: String
    let nestingLevel: [String: GoogleSlidesNestingLevel]
}

struct GoogleSlidesNestingLevel {
    let bulletStyle: GoogleSlidesTextStyle?
}

struct GoogleSlidesShapeProperties {
    let shapeBackgroundFill: GoogleSlidesShapeBackgroundFill?
    let outline: GoogleSlidesOutline?
    let shadow: GoogleSlidesShadow?
    let link: GoogleSlidesLink?
    let contentAlignment: String?
}

struct GoogleSlidesShapeBackgroundFill {
    let solidFill: GoogleSlidesSolidFill?
}

struct GoogleSlidesSolidFill {
    let color: GoogleSlidesOpaqueColor?
    let alpha: Double?
}

struct GoogleSlidesOptionalColor {
    let opaqueColor: GoogleSlidesOpaqueColor?
}

struct GoogleSlidesOpaqueColor {
    let rgbColor: GoogleSlidesRgbColor?
    let themeColor: String?
}

struct GoogleSlidesRgbColor {
    let red: Double
    let green: Double
    let blue: Double
}

struct GoogleSlidesOutline {
    let outlineFill: GoogleSlidesOutlineFill?
    let weight: GoogleSlidesSize?
    let dashStyle: String?
    let propertyState: String?
}

struct GoogleSlidesOutlineFill {
    let solidFill: GoogleSlidesSolidFill?
}

struct GoogleSlidesShadow {
    let type: String
    let transform: GoogleSlidesAffineTransform
    let alignment: String
    let blurRadius: GoogleSlidesSize?
    let color: GoogleSlidesOpaqueColor?
    let alpha: Double?
    let rotateWithShape: Bool?
    let propertyState: String?
}

struct GoogleSlidesLink {
    let url: String?
    let relativeLink: String?
    let pageObjectId: String?
    let slideIndex: Int?
}

struct GoogleSlidesImage {
    let contentUrl: String?
    let imageProperties: GoogleSlidesImageProperties?
}

struct GoogleSlidesImageProperties {
    let cropProperties: GoogleSlidesCropProperties?
    let transparency: Double?
    let brightness: Double?
    let contrast: Double?
    let recolor: GoogleSlidesRecolor?
    let outline: GoogleSlidesOutline?
    let shadow: GoogleSlidesShadow?
    let link: GoogleSlidesLink?
}

struct GoogleSlidesCropProperties {
    let leftOffset: Double?
    let rightOffset: Double?
    let topOffset: Double?
    let bottomOffset: Double?
    let angle: Double?
}

struct GoogleSlidesRecolor {
    let recolorStops: [GoogleSlidesColorStop]?
}

struct GoogleSlidesColorStop {
    let color: GoogleSlidesOpaqueColor
    let alpha: Double?
    let position: Double
}

struct GoogleSlidesVideo {
    let url: String?
    let source: String?
    let id: String?
    let videoProperties: GoogleSlidesVideoProperties?
}

struct GoogleSlidesVideoProperties {
    let outline: GoogleSlidesOutline?
    let autoPlay: Bool?
    let start: Int?
    let end: Int?
    let mute: Bool?
}

struct GoogleSlidesTable {
    let rows: Int
    let columns: Int
    let tableRows: [GoogleSlidesTableRow]
    let horizontalBorderRows: [GoogleSlidesTableBorderRow]?
    let verticalBorderRows: [GoogleSlidesTableBorderRow]?
}

struct GoogleSlidesTableRow {
    let height: GoogleSlidesSize
    let tableCells: [GoogleSlidesTableCell]
}

struct GoogleSlidesTableCell {
    let location: GoogleSlidesTableCellLocation?
    let rowSpan: Int?
    let columnSpan: Int?
    let text: GoogleSlidesTextContent?
    let tableCellProperties: GoogleSlidesTableCellProperties?
}

struct GoogleSlidesTableCellLocation {
    let rowIndex: Int
    let columnIndex: Int
}

struct GoogleSlidesTableCellProperties {
    let tableCellBackgroundFill: GoogleSlidesTableCellBackgroundFill?
    let contentAlignment: String?
}

struct GoogleSlidesTableCellBackgroundFill {
    let solidFill: GoogleSlidesSolidFill?
}

struct GoogleSlidesTableBorderRow {
    let tableBorderCells: [GoogleSlidesTableBorderCell]
}

struct GoogleSlidesTableBorderCell {
    let location: GoogleSlidesTableCellLocation
    let tableBorderProperties: GoogleSlidesTableBorderProperties?
}

struct GoogleSlidesTableBorderProperties {
    let tableBorderFill: GoogleSlidesTableBorderFill?
    let weight: GoogleSlidesSize?
    let dashStyle: String?
}

struct GoogleSlidesTableBorderFill {
    let solidFill: GoogleSlidesSolidFill?
}

struct GoogleSlidesWordArt {
    let renderedText: String?
}

struct GoogleSlidesLine {
    let lineProperties: GoogleSlidesLineProperties?
    let lineType: String?
    let lineCategory: String?
}

struct GoogleSlidesLineProperties {
    let lineFill: GoogleSlidesLineFill?
    let weight: GoogleSlidesSize?
    let dashStyle: String?
    let startArrow: String?
    let endArrow: String?
    let link: GoogleSlidesLink?
    let startConnection: GoogleSlidesLineConnection?
    let endConnection: GoogleSlidesLineConnection?
}

struct GoogleSlidesLineFill {
    let solidFill: GoogleSlidesSolidFill?
}

struct GoogleSlidesLineConnection {
    let connectedObjectId: String
    let connectionSiteIndex: Int?
}

struct GoogleSlidesSheetsChart {
    let spreadsheetId: String
    let chartId: Int
    let contentUrl: String?
    let sheetsChartProperties: GoogleSlidesSheetsChartProperties?
}

struct GoogleSlidesSheetsChartProperties {
    let chartImageProperties: GoogleSlidesImageProperties?
}

struct GoogleSlidesSize {
    let magnitude: Double
    let unit: String
}

struct GoogleSlidesAffineTransform {
    let scaleX: Double
    let scaleY: Double
    let shearX: Double
    let shearY: Double
    let translateX: Double
    let translateY: Double
    let unit: String
}

struct GoogleSlidesPageElementProperties {
    let pageObjectId: String
    let size: GoogleSlidesSize?
    let transform: GoogleSlidesAffineTransform?
}

struct GoogleSlidesRange {
    let startIndex: Int?
    let endIndex: Int?
    let type: String?
}

struct GoogleSlidesLayoutReference {
    let layoutId: String?
    let predefinedLayout: String?
}

struct GoogleSlidesSlideProperties {
    let layoutObjectId: String?
    let masterObjectId: String?
    let notesPage: GoogleSlidesNotesPage?
}

struct GoogleSlidesNotesPage {
    let objectId: String
    let pageElements: [GoogleSlidesPageElement]?
    let notesProperties: GoogleSlidesNotesProperties?
}

struct GoogleSlidesNotesProperties {
    let speakerNotesObjectId: String?
}

struct GoogleSlidesMaster {
    let objectId: String
    let pageElements: [GoogleSlidesPageElement]?
    let masterProperties: GoogleSlidesMasterProperties?
}

struct GoogleSlidesMasterProperties {
    let displayName: String?
}

struct GoogleSlidesLayout {
    let objectId: String
    let pageElements: [GoogleSlidesPageElement]?
    let layoutProperties: GoogleSlidesLayoutProperties?
}

struct GoogleSlidesLayoutProperties {
    let masterObjectId: String?
    let name: String?
    let displayName: String?
} 
