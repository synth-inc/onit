//
//  GoogleSheetsService.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation
import GoogleSignIn

class GoogleSheetsService: GoogleDocumentServiceProtocol {

	var plainTextMimeType: String {
        return "text/csv"
    }
    
    private func readStructuredFile(fileId: String) async throws -> [String: Any] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let apiUrl = "https://sheets.googleapis.com/v4/spreadsheets/\(fileId)"
        
        guard let url = URL(string: apiUrl) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid Google Sheets API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
        
        if httpResponse.statusCode == 404 {
            throw GoogleDriveServiceError.notFound("Onit needs permission to access this file.")
        } else if httpResponse.statusCode == 403 {
            var errorMessage = "Onit can't access this file."
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.accessDenied(errorMessage)
        } else if httpResponse.statusCode != 200 {
            var errorMessage = "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleDriveServiceError.decodingError("Failed to decode document content")
        }
        
        return json
    }
    
    func updateFile(fileId: String, operations: [GoogleSheetsOperation]) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(fileId):batchUpdate"
        
        guard let url = URL(string: urlString) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid batchUpdate URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requests = convertToAPIRequests(operations: operations)
        let body: [String: Any] = [ "requests": requests ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
    }
    
    func convertToAPIRequests(operations: [GoogleSheetsOperation]) -> [[String: Any]] {
        var requests: [[String: Any]] = []
        
        for operation in operations {
            switch operation {
            case .updateCells(let range, let values):
                let rows = values.map { rowValues in
                    [
                        "values": rowValues.map { cellValue in
                            [
                                "userEnteredValue": [
                                    "stringValue": cellValue
                                ]
                            ]
                        }
                    ]
                }
                
                requests.append([
                    "updateCells": [
                        "range": [
                            "sheetId": range.sheetId,
                            "startRowIndex": range.startRowIndex,
                            "endRowIndex": range.endRowIndex,
                            "startColumnIndex": range.startColumnIndex,
                            "endColumnIndex": range.endColumnIndex
                        ],
                        "rows": rows,
                        "fields": "userEnteredValue"
                    ]
                ])
                
            case .insertRows(let sheetId, let startIndex, let endIndex):
                requests.append([
                    "insertDimension": [
                        "range": [
                            "sheetId": sheetId,
                            "dimension": "ROWS",
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ],
                        "inheritFromBefore": false
                    ]
                ])
                
            case .insertColumns(let sheetId, let startIndex, let endIndex):
                requests.append([
                    "insertDimension": [
                        "range": [
                            "sheetId": sheetId,
                            "dimension": "COLUMNS",
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ],
                        "inheritFromBefore": false
                    ]
                ])
                
            case .deleteRows(let sheetId, let startIndex, let endIndex):
                requests.append([
                    "deleteDimension": [
                        "range": [
                            "sheetId": sheetId,
                            "dimension": "ROWS",
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ]
                    ]
                ])
                
            case .deleteColumns(let sheetId, let startIndex, let endIndex):
                requests.append([
                    "deleteDimension": [
                        "range": [
                            "sheetId": sheetId,
                            "dimension": "COLUMNS",
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ]
                    ]
                ])
                
            case .mergeCells(let range):
                requests.append([
                    "mergeCells": [
                        "range": [
                            "sheetId": range.sheetId,
                            "startRowIndex": range.startRowIndex,
                            "endRowIndex": range.endRowIndex,
                            "startColumnIndex": range.startColumnIndex,
                            "endColumnIndex": range.endColumnIndex
                        ],
                        "mergeType": "MERGE_ALL"
                    ]
                ])
                
            case .unmergeCells(let range):
                requests.append([
                    "unmergeCells": [
                        "range": [
                            "sheetId": range.sheetId,
                            "startRowIndex": range.startRowIndex,
                            "endRowIndex": range.endRowIndex,
                            "startColumnIndex": range.startColumnIndex,
                            "endColumnIndex": range.endColumnIndex
                        ]
                    ]
                ])
                
            case .addSheet(let title):
                requests.append([
                    "addSheet": [
                        "properties": [
                            "title": title
                        ]
                    ]
                ])
                
            case .updateCellFormat(let range, let format):
                var cellFormatDict: [String: Any] = [:]
                
                if let numberFormat = format.numberFormat {
                    cellFormatDict["numberFormat"] = [
                        "type": numberFormat.type,
                        "pattern": numberFormat.pattern ?? ""
                    ]
                }
                
                if let backgroundColor = format.backgroundColor {
                    cellFormatDict["backgroundColor"] = [
                        "red": (backgroundColor.red ?? 0) as Any,
                        "green": (backgroundColor.green ?? 0) as Any,
                        "blue": (backgroundColor.blue ?? 0) as Any,
                        "alpha": (backgroundColor.alpha ?? 1) as Any
                    ]
                }
                
                if let textFormat = format.textFormat {
                    var textFormatDict: [String: Any] = [:]
                    if let foregroundColor = textFormat.foregroundColor {
                        textFormatDict["foregroundColor"] = [
                            "red": (foregroundColor.red ?? 0) as Any,
                            "green": (foregroundColor.green ?? 0) as Any,
                            "blue": (foregroundColor.blue ?? 0) as Any,
                            "alpha": (foregroundColor.alpha ?? 1) as Any
                        ]
                    }
                    if let fontFamily = textFormat.fontFamily { textFormatDict["fontFamily"] = fontFamily }
                    if let fontSize = textFormat.fontSize { textFormatDict["fontSize"] = fontSize }
                    if let bold = textFormat.bold { textFormatDict["bold"] = bold }
                    if let italic = textFormat.italic { textFormatDict["italic"] = italic }
                    
                    cellFormatDict["textFormat"] = textFormatDict
                }
                
                requests.append([
                    "repeatCell": [
                        "range": [
                            "sheetId": range.sheetId,
                            "startRowIndex": range.startRowIndex,
                            "endRowIndex": range.endRowIndex,
                            "startColumnIndex": range.startColumnIndex,
                            "endColumnIndex": range.endColumnIndex
                        ],
                        "cell": [
                            "userEnteredFormat": cellFormatDict
                        ],
                        "fields": "userEnteredFormat"
                    ]
                ])
                
            case .addChart(let sheetId, let chartSpec):
                var chartSpecDict: [String: Any] = [:]
                
                if let title = chartSpec.title {
                    chartSpecDict["title"] = title
                }
                
                if let basicChart = chartSpec.basicChart {
                    chartSpecDict["basicChart"] = [
                        "chartType": basicChart.chartType,
                        "legendPosition": basicChart.legendPosition ?? "BOTTOM_LEGEND"
                    ]
                }
                
                requests.append([
                    "addChart": [
                        "chart": [
                            "spec": chartSpecDict,
                            "position": [
                                "overlayPosition": [
                                    "anchorCell": [
                                        "sheetId": sheetId,
                                        "rowIndex": 0,
                                        "columnIndex": 0
                                    ]
                                ]
                            ]
                        ]
                    ]
                ])
                
            case .setFormula(let range, let formula):
                requests.append([
                    "updateCells": [
                        "range": [
                            "sheetId": range.sheetId,
                            "startRowIndex": range.startRowIndex,
                            "endRowIndex": range.endRowIndex,
                            "startColumnIndex": range.startColumnIndex,
                            "endColumnIndex": range.endColumnIndex
                        ],
                        "rows": [
                            [
                                "values": [
                                    [
                                        "userEnteredValue": [
                                            "formulaValue": formula
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        "fields": "userEnteredValue"
                    ]
                ])
            }
        }
        
        return requests
    }
    
    // MARK: - Private Helper Methods
    
    private func parseGoogleSheetsSpreadsheet(from data: [String: Any]) throws -> GoogleSheetsSpreadsheet {
        guard let spreadsheetId = data["spreadsheetId"] as? String,
              let propertiesData = data["properties"] as? [String: Any],
              let sheetsArray = data["sheets"] as? [[String: Any]] else {
            throw GoogleDriveServiceError.invalidResponse("Invalid Google Sheets structure")
        }
        
        let properties = parseGoogleSheetsSpreadsheetProperties(from: propertiesData)
        let sheets = sheetsArray.compactMap { sheetData in
            parseGoogleSheetsSheet(from: sheetData)
        }
        
        return GoogleSheetsSpreadsheet(
            spreadsheetId: spreadsheetId,
            properties: properties,
            sheets: sheets
        )
    }
    
    private func parseGoogleSheetsSpreadsheetProperties(from data: [String: Any]) -> GoogleSheetsSpreadsheetProperties {
        let title = data["title"] as? String ?? "Untitled Spreadsheet"
        let locale = data["locale"] as? String
        let autoRecalc = data["autoRecalc"] as? String
        
        return GoogleSheetsSpreadsheetProperties(
            title: title,
            locale: locale,
            autoRecalc: autoRecalc
        )
    }
    
    private func parseGoogleSheetsSheet(from data: [String: Any]) -> GoogleSheetsSheet? {
        guard let propertiesData = data["properties"] as? [String: Any] else {
            return nil
        }
        
        let properties = parseGoogleSheetsSheetProperties(from: propertiesData)
        let data_array = data["data"] as? [[String: Any]]
        let gridData = data_array?.compactMap { parseGoogleSheetsGridData(from: $0) }
        
        return GoogleSheetsSheet(
            properties: properties,
            data: gridData,
            merges: nil, // Simplified for now
            charts: nil  // Simplified for now
        )
    }
    
    private func parseGoogleSheetsSheetProperties(from data: [String: Any]) -> GoogleSheetsSheetProperties {
        let sheetId = data["sheetId"] as? Int ?? 0
        let title = data["title"] as? String ?? "Sheet1"
        let sheetType = data["sheetType"] as? String
        
        var gridProperties: GoogleSheetsGridProperties?
        if let gridPropsData = data["gridProperties"] as? [String: Any] {
            gridProperties = GoogleSheetsGridProperties(
                rowCount: gridPropsData["rowCount"] as? Int ?? 1000,
                columnCount: gridPropsData["columnCount"] as? Int ?? 26,
                frozenRowCount: gridPropsData["frozenRowCount"] as? Int,
                frozenColumnCount: gridPropsData["frozenColumnCount"] as? Int
            )
        }
        
        return GoogleSheetsSheetProperties(
            sheetId: sheetId,
            title: title,
            sheetType: sheetType,
            gridProperties: gridProperties
        )
    }
    
    private func parseGoogleSheetsGridData(from data: [String: Any]) -> GoogleSheetsGridData? {
        let startRow = data["startRow"] as? Int
        let startColumn = data["startColumn"] as? Int
        
        guard let rowDataArray = data["rowData"] as? [[String: Any]] else {
            return nil
        }
        
        let rowData = rowDataArray.compactMap { parseGoogleSheetsRowData(from: $0) }
        
        return GoogleSheetsGridData(
            startRow: startRow,
            startColumn: startColumn,
            rowData: rowData
        )
    }
    
    private func parseGoogleSheetsRowData(from data: [String: Any]) -> GoogleSheetsRowData? {
        guard let valuesArray = data["values"] as? [[String: Any]] else {
            return nil
        }
        
        let values = valuesArray.compactMap { parseGoogleSheetsCellData(from: $0) }
        
        return GoogleSheetsRowData(values: values)
    }
    
    private func parseGoogleSheetsCellData(from data: [String: Any]) -> GoogleSheetsCellData {
        var userEnteredValue: GoogleSheetsExtendedValue?
        if let valueData = data["userEnteredValue"] as? [String: Any] {
            userEnteredValue = parseGoogleSheetsExtendedValue(from: valueData)
        }
        
        let formattedValue = data["formattedValue"] as? String
        
        return GoogleSheetsCellData(
            userEnteredValue: userEnteredValue,
            formattedValue: formattedValue,
            userEnteredFormat: nil, // Simplified for now
            effectiveFormat: nil,   // Simplified for now
            effectiveValue: nil     // Simplified for now
        )
    }
    
    private func parseGoogleSheetsExtendedValue(from data: [String: Any]) -> GoogleSheetsExtendedValue {
        return GoogleSheetsExtendedValue(
            numberValue: data["numberValue"] as? Double,
            stringValue: data["stringValue"] as? String,
            boolValue: data["boolValue"] as? Bool,
            formulaValue: data["formulaValue"] as? String
        )
    }
} 
