//
//  GoogleSheetsOperations.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation

enum GoogleSheetsOperation {
    case updateCells(range: GoogleSheetsRange, values: [[String]])
    case insertRows(sheetId: Int, startIndex: Int, endIndex: Int)
    case insertColumns(sheetId: Int, startIndex: Int, endIndex: Int)
    case deleteRows(sheetId: Int, startIndex: Int, endIndex: Int)
    case deleteColumns(sheetId: Int, startIndex: Int, endIndex: Int)
    case mergeCells(range: GoogleSheetsRange)
    case unmergeCells(range: GoogleSheetsRange)
    case addSheet(title: String)
    case updateCellFormat(range: GoogleSheetsRange, format: GoogleSheetsCellFormat)
    case addChart(sheetId: Int, chartSpec: GoogleSheetsChartSpec)
    case setFormula(range: GoogleSheetsRange, formula: String)
}

struct GoogleSheetsDiff {
    let fileId: String
    let spreadsheetStructure: GoogleSheetsSpreadsheet
    let originalText: String
    let proposedOperations: [GoogleSheetsOperation]
    let previewText: String
}

struct GoogleSheetsSpreadsheet {
    let spreadsheetId: String
    let properties: GoogleSheetsSpreadsheetProperties
    let sheets: [GoogleSheetsSheet]
}

struct GoogleSheetsSpreadsheetProperties {
    let title: String
    let locale: String?
    let autoRecalc: String?
}

struct GoogleSheetsSheet {
    let properties: GoogleSheetsSheetProperties
    let data: [GoogleSheetsGridData]?
    let merges: [GoogleSheetsRange]?
    let charts: [GoogleSheetsEmbeddedChart]?
}

struct GoogleSheetsSheetProperties {
    let sheetId: Int
    let title: String
    let sheetType: String?
    let gridProperties: GoogleSheetsGridProperties?
}

struct GoogleSheetsGridProperties {
    let rowCount: Int
    let columnCount: Int
    let frozenRowCount: Int?
    let frozenColumnCount: Int?
}

struct GoogleSheetsGridData {
    let startRow: Int?
    let startColumn: Int?
    let rowData: [GoogleSheetsRowData]
}

struct GoogleSheetsRowData {
    let values: [GoogleSheetsCellData]
}

struct GoogleSheetsCellData {
    let userEnteredValue: GoogleSheetsExtendedValue?
    let formattedValue: String?
    let userEnteredFormat: GoogleSheetsCellFormat?
    let effectiveFormat: GoogleSheetsCellFormat?
    let effectiveValue: GoogleSheetsExtendedValue?
}

struct GoogleSheetsExtendedValue {
    let numberValue: Double?
    let stringValue: String?
    let boolValue: Bool?
    let formulaValue: String?
}

struct GoogleSheetsCellFormat {
    let numberFormat: GoogleSheetsNumberFormat?
    let backgroundColor: GoogleSheetsColor?
    let textFormat: GoogleSheetsTextFormat?
    let horizontalAlignment: String?
    let verticalAlignment: String?
    let wrapStrategy: String?
}

struct GoogleSheetsNumberFormat {
    let type: String
    let pattern: String?
}

struct GoogleSheetsTextFormat {
    let foregroundColor: GoogleSheetsColor?
    let fontFamily: String?
    let fontSize: Int?
    let bold: Bool?
    let italic: Bool?
    let strikethrough: Bool?
    let underline: Bool?
}

struct GoogleSheetsColor {
    let red: Float?
    let green: Float?
    let blue: Float?
    let alpha: Float?
}

struct GoogleSheetsRange {
    let sheetId: Int
    let startRowIndex: Int
    let endRowIndex: Int
    let startColumnIndex: Int
    let endColumnIndex: Int
}

struct GoogleSheetsEmbeddedChart {
    let chartId: Int
    let spec: GoogleSheetsChartSpec
    let position: GoogleSheetsEmbeddedObjectPosition
}

struct GoogleSheetsChartSpec {
    let title: String?
    let basicChart: GoogleSheetsBasicChartSpec?
    let pieChart: GoogleSheetsPieChartSpec?
}

struct GoogleSheetsBasicChartSpec {
    let chartType: String
    let legendPosition: String?
    let axis: [GoogleSheetsBasicChartAxis]?
    let domains: [GoogleSheetsBasicChartDomain]?
    let series: [GoogleSheetsBasicChartSeries]?
}

struct GoogleSheetsPieChartSpec {
    let legendPosition: String?
    let domain: GoogleSheetsPieChartDomain?
    let series: GoogleSheetsPieChartSeries?
}

struct GoogleSheetsBasicChartAxis {
    let position: String
    let title: String?
}

struct GoogleSheetsBasicChartDomain {
    let domain: GoogleSheetsChartData
}

struct GoogleSheetsBasicChartSeries {
    let series: GoogleSheetsChartData
    let type: String?
}

struct GoogleSheetsPieChartDomain {
    let domain: GoogleSheetsChartData
}

struct GoogleSheetsPieChartSeries {
    let series: GoogleSheetsChartData
}

struct GoogleSheetsChartData {
    let sourceRange: GoogleSheetsChartSourceRange
}

struct GoogleSheetsChartSourceRange {
    let sources: [GoogleSheetsGridRange]
}

struct GoogleSheetsGridRange {
    let sheetId: Int
    let startRowIndex: Int?
    let endRowIndex: Int?
    let startColumnIndex: Int?
    let endColumnIndex: Int?
}

struct GoogleSheetsEmbeddedObjectPosition {
    let sheetId: Int
    let overlayPosition: GoogleSheetsOverlayPosition?
}

struct GoogleSheetsOverlayPosition {
    let anchorCell: GoogleSheetsGridCoordinate
    let offsetXPixels: Int?
    let offsetYPixels: Int?
    let widthPixels: Int?
    let heightPixels: Int?
}

struct GoogleSheetsGridCoordinate {
    let sheetId: Int
    let rowIndex: Int
    let columnIndex: Int
} 