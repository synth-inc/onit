//
//  TypeaheadTestingService.swift
//  Onit
//
//  Created by Kévin Naudin on 04/03/2025.
//

import AppKit
import Defaults
import Foundation
import PostHog
import SwiftData

@MainActor
@Observable
class TypeaheadTestingService {
    static let shared = TypeaheadTestingService()
    private let testCasesLimit: Int = 50
    private let localModelsLimit: Int = 5
    private let syncInterval: TimeInterval = 24 * 60 * 60 // 24 heures
    
    // TODO: KNA - Should be called somewhere
    func checkUserConsent() {
        let config = Defaults[.typeaheadLearningConfig]
        
        if Defaults[.typeaheadLearningConfig].hasUserConsent == nil {
            Task {
                let consent = await requestUserConsent()
                
                Defaults[.typeaheadLearningConfig].hasUserConsent = consent
                
                if consent {
                    startRemoteTestSync()
                }
            }
        } else if config.hasUserConsent == true {
            startRemoteTestSync()
        }
    }
    
    private func requestUserConsent() async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Help improve Autocompletion"
                alert.informativeText = "Would you like to contribute to improving autocompletion by allowing local tests to run? No personal data will be shared."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Accept")
                alert.addButton(withTitle: "Deny")
                
                let response = alert.runModal()
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }
    
    private func startRemoteTestSync() {
        Task {
            while true {
                await syncRemoteTests()
                try? await Task.sleep(nanoseconds: UInt64(syncInterval * 1_000_000_000))
            }
        }
    }
    
    private func syncRemoteTests() async {
        let config = Defaults[.typeaheadLearningConfig]
        
        guard config.isEnabled,
              config.hasUserConsent == true,
              let tests = await fetchRemoteTests() else { return }
        
        let results = await runTests(tests.tests)
        await submitTestResults(results)
        
        Defaults[.typeaheadLearningConfig].lastSyncVersion = tests.version
    }
    
    private func runTests(_ tests: [TypeaheadTest]) async -> [TypeaheadTestResult] {
        // Error occured when fetching test cases or no test case found
        guard let testCases = try? await TypeaheadLearningService.shared.getCases(limit: testCasesLimit),
              !testCases.isEmpty else { return [] }
        
        let availableLocalModels = Defaults[.availableLocalModels]
            .shuffled()
            .prefix(localModelsLimit)
        
        var results: [TypeaheadTestResult] = []
        
        for test in tests {
            for testCase in testCases {
                for localModel in availableLocalModels {
                    do {
                        let metrics = try await runTest(model: localModel, test: test, testCase: testCase)
                        
                        results.append(TypeaheadTestResult(
                            testId: test.id,
                            success: true,
                            metrics: metrics,
                            error: nil
                        ))
                    } catch {
                        results.append(TypeaheadTestResult(
                            testId: test.id,
                            success: false,
                            metrics: [:],
                            error: error.localizedDescription
                        ))
                    }
                }
            }
        }
        
        return results
    }
    
    private func runTest(model: String, test: TypeaheadTest, testCase: TypeaheadCase) async throws -> [String: Double] {
        let localMessages = buildMessages(testCase: testCase, systemMessage: test.systemMessage, userMessage: test.userMessage)
        let keepAlive: String? = test.parameters[TypeaheadTest.Parameter.keepAlive]
        var options = LocalChatOptions()
        
        if let numCtx = test.parameters[TypeaheadTest.Parameter.numCtx] {
            options.num_ctx = Int(numCtx)
        }
        if let temperature = test.parameters[TypeaheadTest.Parameter.temperature] {
            options.temperature = Double(temperature)
        }
        if let topK = test.parameters[TypeaheadTest.Parameter.topK] {
            options.top_k = Int(topK)
        }
        if let topP = test.parameters[TypeaheadTest.Parameter.topP] {
            options.top_p = Double(topP)
        }
        
        let startDate = Date()
        let response = try await performRequest(
            model: model,
            localMessages: localMessages,
            keepAlive: keepAlive,
            options: options
        )
        let elapsedTime = Date().timeIntervalSince(startDate)
        
        var metrics: [String: Double] = [:]
        
        metrics[TypeaheadTestResult.Metric.elapsedTime] = elapsedTime
        metrics[TypeaheadTestResult.Metric.tokenPerSecond] = Double(response.count) / elapsedTime
        
        metrics[TypeaheadTestResult.Metric.completionLength] = Double(response.count)
        if let aiCompletion = testCase.aiCompletion {
            metrics[TypeaheadTestResult.Metric.similarityScore] = calculateSimilarity(between: response, and: aiCompletion)
        }
        metrics[TypeaheadTestResult.Metric.contextRelevance] = calculateContextRelevance(
            completion: response,
            context: testCase.screenContent
        )
        
        metrics[TypeaheadTestResult.Metric.contextLength] = Double(testCase.screenContent.count)
        metrics[TypeaheadTestResult.Metric.precedingTextLength] = Double(testCase.precedingText.count)
        metrics[TypeaheadTestResult.Metric.followingTextLength] = Double(testCase.followingText.count)
        
        return metrics
    }
    
    private func calculateSimilarity(between str1: String, and str2: String) -> Double {
        let set1 = Set(str1.components(separatedBy: .whitespacesAndNewlines))
        let set2 = Set(str2.components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return Double(intersection) / Double(union)
    }
    
    private func calculateContextRelevance(completion: String, context: String) -> Double {
        let completionWords = Set(completion.components(separatedBy: .whitespacesAndNewlines))
        let contextWords = Set(context.components(separatedBy: .whitespacesAndNewlines))
        
        let commonWords = completionWords.intersection(contextWords).count
        return Double(commonWords) / Double(completionWords.count)
    }
    
    private func buildMessages(testCase: TypeaheadCase, systemMessage: String, userMessage: String) -> [LocalChatMessage] {
        let finalSystemMessage = systemMessage
            .replacingOccurrences(of: TypeaheadTest.Message.applicationName, with: testCase.applicationName)
            .replacingOccurrences(of: TypeaheadTest.Message.applicationTitle, with: testCase.applicationTitle ?? "")
            .replacingOccurrences(of: TypeaheadTest.Message.followingText, with: testCase.followingText)
            .replacingOccurrences(of: TypeaheadTest.Message.precedingText, with: testCase.precedingText)
            .replacingOccurrences(of: TypeaheadTest.Message.fullText, with: testCase.currentText)
            .replacingOccurrences(of: TypeaheadTest.Message.screenContent, with: testCase.screenContent)
        let finalUserMessage = userMessage
            .replacingOccurrences(of: TypeaheadTest.Message.applicationName, with: testCase.applicationName)
            .replacingOccurrences(of: TypeaheadTest.Message.applicationTitle, with: testCase.applicationTitle ?? "")
            .replacingOccurrences(of: TypeaheadTest.Message.followingText, with: testCase.followingText)
            .replacingOccurrences(of: TypeaheadTest.Message.precedingText, with: testCase.precedingText)
            .replacingOccurrences(of: TypeaheadTest.Message.fullText, with: testCase.currentText)
            .replacingOccurrences(of: TypeaheadTest.Message.screenContent, with: testCase.screenContent)
        
        return [
            LocalChatMessage(role: "system", content: finalSystemMessage, images: nil),
            LocalChatMessage(role: "user", content: finalUserMessage, images: nil)
        ]
    }
    
    private func performRequest(
        model: String,
        localMessages: [LocalChatMessage],
        keepAlive: String?,
        options: LocalChatOptions
    ) async throws -> String {
        
        return try await Task {
            do {
                let response = try await FetchingClient().localChat(
                    model: model,
                    localMessages: localMessages,
                    keepAlive: keepAlive,
                    options: options
                )
                
                return response
            } catch {
                throw error
            }
        }.value
    }
    
    private func fetchRemoteTests() async -> TypeaheadTests? {
        guard let payload = PostHogSDK.shared.getFeatureFlagPayload("typeahead_tests") else {
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            let decoder = JSONDecoder()
            let tests = try decoder.decode(TypeaheadTests.self, from: jsonData)
            
            if let lastVersion = Defaults[.typeaheadLearningConfig].lastSyncVersion,
               lastVersion >= tests.version {
                return nil
            }
            
            return tests
        } catch {
            return nil
        }
    }
    
    private func submitTestResults(_ results: [TypeaheadTestResult]) async {
        // TODO: KNA - Implement API call
    }
} 
