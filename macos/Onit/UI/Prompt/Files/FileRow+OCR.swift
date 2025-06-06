//
//  FileRow+OCR.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

extension FileRow {
    
    func processContextChangesWithOCR(oldContexts: [Context], newContexts: [Context]) async -> (String, Int)? {
        guard var newAutoContext = findNewAutoContext(oldContexts: oldContexts,
                                                      newContexts: newContexts) else {
            return nil
        }
        
        do {
            let (observations, screenshot) = try await OCRManager.shared.extractTextFromApp(newAutoContext.appName)
            
            // Join all OCR text observations into a single string
            let extractedText = observations.map(\.text).joined(separator: " ")
            let matchPercentage = compareOCRWithAutoContext(ocrText: extractedText, autoContext: newAutoContext)
            
            if let firstIndex = windowState.pendingContextList.firstIndex(where: {
                if case .auto(let autoContext) = $0 {
                    return autoContext == newAutoContext
                }
                return false
            }) {
                newAutoContext.ocrMatchingPercentage = matchPercentage
                windowState.pendingContextList[firstIndex] = .auto(newAutoContext)
            }
            
            return (extractedText, matchPercentage)
        } catch {
            log.error("Failed to extract text from \(newAutoContext.appName): \(error)")
            return nil
        }
    }
    
    // MARK: - Private functions

    private func findNewAutoContext(oldContexts: [Context], newContexts: [Context]) -> AutoContext? {
        let oldAutoContexts = Set(oldContexts.compactMap { context in
            if case .auto(let autoContext) = context {
                return autoContext
            }
            return nil
        })
        let newAutoContexts = Set(newContexts.compactMap { context in
            if case .auto(let autoContext) = context {
                return autoContext
            }
            return nil
        })
        let addedAutoContexts = newAutoContexts.subtracting(oldAutoContexts)
        
        return addedAutoContexts.first
    }
    
    private func compareOCRWithAutoContext(ocrText: String, autoContext: AutoContext) -> Int {
        guard let screenContent = autoContext.appContent["screen"] else {
            return 0
        }
        
        let ocrWords = ocrText.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 1 }
        
        let screenWords = screenContent.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 1 }
        
        guard !ocrWords.isEmpty, !screenWords.isEmpty else { return 0 }
        
        let screenWordsSet = Set(screenWords)
        let matchingWords = ocrWords.filter { screenWordsSet.contains($0) }
        
        let percentage = (Double(matchingWords.count) / Double(ocrWords.count)) * 100.0
        
        return Int(percentage.rounded())
    }
}
