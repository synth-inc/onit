//
//  OnitPanelState+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit
import Defaults

extension OnitPanelState {
    func addAutoContext(trackedWindow: TrackedWindow? = nil, screenResult: ScreenResult? = nil, wasTriggeredAutomatically: Bool = false) {
        guard Defaults[.autoContextFromCurrentWindow] else { return }
        
        // When automatically triggered, only add the context if the tracked window still matches the current foreground window.
        if wasTriggeredAutomatically,
           let window = trackedWindow,
           let currentFG = self.foregroundWindow,
           window.hash != currentFG.hash || window.title != currentFG.title {
            log.warning("Discarding auto context: active window has changed (from \(window.title) to \(currentFG.title)).")
            return
        }

        let appName = screenResult?.applicationName ?? "AutoContext"
        let trackedWindowTitle = trackedWindow?.title
        let trackedWindowHash = trackedWindow?.hash ?? 0
        if let errorMessage = screenResult?.errorMessage {
            let errorContext = Context(
                appName: appName,
                appHash: trackedWindow?.hash ?? 0,
                appTitle: trackedWindowTitle ?? "Unknown",
                appContent: ["error": errorMessage, "errorCode" : String(screenResult?.errorCode ?? 0)],
                appBundleUrl: screenResult?.appBundleUrl)
            pendingContextList.insert(errorContext, at: 0)
            cleanupWindowContextTask(uniqueWindowIdentifier: trackedWindowHash)
            return
        }

        guard var appContent = screenResult?.others else {
            let errorContext = Context(appName: "Unable to add \(appName)", appHash: 0, appTitle: "", appContent: ["error": "Empty text"])
            pendingContextList.insert(errorContext, at: 0)
            cleanupWindowContextTask(uniqueWindowIdentifier: trackedWindowHash)
            return
        }
        
        guard let activeTrackedWindow = trackedWindow ?? self.foregroundWindow else {
            // No window could be identified. On an automatic trigger (panel just
            // opened) this is an expected transient — the foreground window may not
            // be resolved yet — so fail silently rather than flashing a scary
            // "Cannot identify context" chip. Only surface the error for an explicit
            // manual add, where the user is waiting on feedback.
            if !wasTriggeredAutomatically {
                let errorContext = Context(appName: "Unable to add \(appName)", appHash: 0, appTitle: "", appContent: ["error": "Cannot identify context"])
                pendingContextList.insert(errorContext, at: 0)
            }
            cleanupWindowContextTask(uniqueWindowIdentifier: trackedWindowHash)
            return
        }
        let appHash = activeTrackedWindow.hash
        let appTitle = trackedWindow?.title ?? activeTrackedWindow.title
        
        // Optionally add the OCR percentage, if it exists. 
        let ocrMatchingPercentage = getOCRMatchingPercentage(for: appTitle)
        // Set an error when the OCR matching is low. 
        if let ocrMatchingPercentage = ocrMatchingPercentage {
            if ocrMatchingPercentage < 50 {
                appContent["error"] = "Low OCR match: \(ocrMatchingPercentage)%"
                appContent["errorCode"] = "1800"
            } else if ocrMatchingPercentage < 75 {
                appContent["warning"] = "Low OCR match: \(ocrMatchingPercentage)%"
            }
        }

        if let existingIndex = pendingContextList.firstIndex(where: { context in
            if case .auto(let autoContext) = context {
                return autoContext.appTitle == appTitle && autoContext.appHash == appHash
            }
            return false
        }) {
            /// For now, we're simply replacing the context.
            /// Later on, we should implement a data aggregator.
            let oldContext = pendingContextList[existingIndex]
            let autoContext = AutoContext(
                appName: appName,
                appHash: appHash,
                appTitle: appTitle,
                appContent: appContent,
                appBundleUrl: screenResult?.appBundleUrl,
                ocrMatchingPercentage: ocrMatchingPercentage
            )
            let newContext = Context.auto(autoContext)
            
            // Always assign to update content; equality now based on identity so this won't disrupt windows/UI
            pendingContextList[existingIndex] = newContext
            
            cleanupWindowContextTask(uniqueWindowIdentifier: appHash)
            
            return
            
            /** Merge result for existing autoContext */
//            if case .auto(let autoContext) = pendingContextList[existingIndex] {
//                var existingContent = autoContext.appContent
//                let appContentString = appContent[AccessibilityParsedElements.screen] ?? ""
//                let contentString = existingContent[AccessibilityParsedElements.screen] ?? ""
//
//                if !appContentString.isEmpty && !contentString.isEmpty {
//                    let mergedContent = mergeFragments([contentString, appContentString])
//                    existingContent[AccessibilityParsedElements.screen] = mergedContent
//
//                    let updatedContext = Context(appName: appName, appHash: appHash, appTitle: appTitle, appContent: existingContent)
//                    pendingContextList[existingIndex] = updatedContext
//
//                    return
//                }
//            }
        }
        
        let autoContext = AutoContext(
            appName: appName,
            appHash: appHash,
            appTitle: appTitle,
            appContent: appContent,
            appBundleUrl: screenResult?.appBundleUrl,
            ocrMatchingPercentage: ocrMatchingPercentage
        )
        
        let context = Context.auto(autoContext)
        pendingContextList.insert(context, at: 0)
        cleanupWindowContextTask(uniqueWindowIdentifier: appHash)
    }
    
    private func getOCRMatchingPercentage(for appTitle: String) -> Int? {
        // Find the most recent OCR result that matches the app title
        let recentResult = DebugManager.shared.ocrComparisonResults
            .filter { result in
                result.appTitle == appTitle &&
                Date().timeIntervalSince(result.timestamp) < 300 // Within last 5 minutes
            }
            .sorted { $0.timestamp > $1.timestamp }
            .first
        
        return recentResult?.matchPercentage
    }
    
    func cleanupWindowContextTask(uniqueWindowIdentifier: UInt) {
        windowContextTasks[uniqueWindowIdentifier]?.cancel()
        windowContextTasks.removeValue(forKey: uniqueWindowIdentifier)
    }
    
    func refreshWindowContextElements() async {
        guard !pendingContextList.isEmpty else { return }
        
        // Get all autocontext elements that need refreshing
        let autocontextElements = pendingContextList.compactMap { context -> (Context, TrackedWindow)? in
            guard case .auto(let autoContext) = context else { return nil }
            
            // Find the tracked window for this autocontext element
            let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.findTrackedWindow(
                trackedWindowHash: autoContext.appHash
            )
            
            return trackedWindow.map { (context, $0) }
        }
        
        guard !autocontextElements.isEmpty else { return }
                
        // Collect all tasks to await
        var refreshTasks: [Task<Void, Never>] = []
        
        // Refresh each autocontext element
        for (context, trackedWindow) in autocontextElements {
            // Remove the old context by finding it in the list
            if let index = pendingContextList.firstIndex(where: { 
                if case .auto(let existingAutoContext) = $0,
                   case .auto(let currentAutoContext) = context {
                    return existingAutoContext == currentAutoContext
                }
                return false
            }) {
                pendingContextList.remove(at: index)
            }
            
            // Trigger a fresh context fetch and collect the task
            if let task = ContextFetchingService.shared.retrieveWindowContent(
                state: self,
                trackedWindow: trackedWindow,
                wasTriggeredAutomatically: false
            ) {
                refreshTasks.append(task)
            }
        }
        
        // Wait for all context fetching tasks to complete
        await withTaskGroup(of: Void.self) { group in
            for task in refreshTasks {
                group.addTask {
                    await task.value
                }
            }
        }
    }
    
    func cleanUpPendingWindowContextTasks() {
        for (_, task) in windowContextTasks {
            task.cancel()
        }
        
        windowContextTasks = [:]
    }
    
    func addWindowToContext(window: AXUIElement) {
        guard let windowPid = window.pid() else { return }
        
        guard let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.trackWindowForElement(
            window,
            pid: windowPid
        ) else {
            return
        }
        
        let windowApp = WindowHelpers.getWindowApp(pid: trackedWindow.pid)
        let appBundleUrl = windowApp?.bundleURL
        
        ContextFetchingService.shared.retrieveWindowContent(
            state: self,
            trackedWindow: trackedWindow,
            customAppBundleUrl: appBundleUrl
        )
    }

    func getPendingContextList() -> [Context] {
        return pendingContextList
    }

    func addContext(urls: [URL]) {
        let contextItems = urls.map(Context.init)
        pendingContextList += contextItems
        
        for context in contextItems {
            if case .web(let websiteUrl, _, _) = context {
                addWebsiteUrlScrapeTask(
                    websiteUrl: websiteUrl,
                    scrapeTask: Task { await scrapeWebsiteUrl(websiteUrl: websiteUrl) }
                )
            }
        }

        // We are going to upload the images to
        //        if preferences.mode == .remote {
        //            tryToUpload(contextItems)
        //        }
    }

    func addContext(images: [NSImage]) {
        let tempDirectory = FileManager.default.temporaryDirectory

        var imageURLs: [URL] = []
        for image in images {
            let uniqueFileName = UUID().uuidString + ".png"
            let fileURL = tempDirectory.appendingPathComponent(uniqueFileName)

            if let tiffData = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData),
                let pngData = bitmap.representation(using: .png, properties: [:])
            {
                do {
                    try pngData.write(to: fileURL)
                    imageURLs.append(fileURL)
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            }
        }

        addContext(urls: imageURLs)
    }

    func newChat(clearContext: Bool = true, shouldSystemPrompt: Bool = false) {
        historyIndex = -1
        currentChat = nil
        currentPrompts = nil
        pendingInstruction = ""
        if (clearContext) {
            pendingContextList.removeAll()
            pendingInput = nil
            
            // Cancel all pending context fetching tasks to prevent
            // addAutoContext from being called when they complete
            cleanUpPendingWindowContextTasks()
        }
        focusText()
        
        systemPromptState.shouldShowSelection = false
        systemPromptState.userSelectedPrompt = false
        let suggestedPrompts = promptSuggestionService?.suggestedPrompts ?? []
        systemPromptState.shouldShowSystemPrompt = shouldSystemPrompt || !suggestedPrompts.isEmpty
    }

    func removeContext(context: Context) {
        switch context {
        case .image(let url):
            uploadTasks[url]?.cancel()
            uploadTasks[url] = nil
            imageUploads[url] = nil
        case .web(let websiteUrl, _, let existingWebFileUrl): // Handles removing temporary local web files.
            removeWebsiteUrlScrapeTask(websiteUrl: websiteUrl)
            
            if let existingWebFileUrl = existingWebFileUrl {
                do {
                    try FileManager.default.removeItem(at: existingWebFileUrl)
                } catch {
                    #if DEBUG
                    print("Failed to delete web content file: \(error)")
                    #endif
                }
            }
        case .auto(let autoContextItem):
            cleanupWindowContextTask(uniqueWindowIdentifier: autoContextItem.appHash)
        default:
            break
        }
        
        self.pendingContextList.removeAll { $0 == context }
    }

    func focusText() {
        textFocusTrigger.toggle()
    }

    func tryToUpload(_ context: [Context]) {
        for item in context {
            if case .image(let imageUpload) = item {
                uploadAndMonitor(imageUpload)
            }
        }
    }

    func uploadAndMonitor(_ url: URL) {
        let uploadTask = Task<URL?, Never> {
            for await progress in await client.upload(image: url) {
                imageUploads[url] = progress
                if case .completed(let remote) = progress {
                    return remote
                }
            }
            return nil
        }
        uploadTasks[url] = uploadTask
    }

    // TODO removing these unless we move back to an upload model
    //    var remoteImages: [URL] {
    //        get async {
    //            var images: [URL] = []
    //            for task in uploadTasks.values {
    //                if let url = await task.value {
    //                    images.append(url)
    //                }
    //            }
    //            return images
    //        }
    //    }

    //    var localImages: [URL] {
    //        var images: [URL] = []
    //        for item in pendingContextList {
    //            if case .image(let url) = item {
    //                images.append(url)
    //            }
    //        }
    //        return images
    //    
}
