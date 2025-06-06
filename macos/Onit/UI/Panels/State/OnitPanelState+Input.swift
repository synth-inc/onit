//
//  OnitPanelState+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit
import Defaults

extension OnitPanelState {
    func addAutoContext() {
        guard Defaults[.autoContextFromCurrentWindow] else { return }

        let appName = AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "AutoContext"
        if let errorMessage = AccessibilityNotificationsManager.shared.screenResult.errorMessage {
            let errorContext = Context(appName: "Unable to add \(appName)", appHash: 0, appTitle: "", appContent: ["error": errorMessage])
            pendingContextList.insert(errorContext, at: 0)
            return
        }

        guard let appContent = AccessibilityNotificationsManager.shared.screenResult.others else {
            let errorContext = Context(appName: "Unable to add \(appName)", appHash: 0, appTitle: "", appContent: ["error": "Empty text"])
            pendingContextList.insert(errorContext, at: 0)
            return
        }
        guard let activeTrackedWindow = AccessibilityNotificationsManager.shared.windowsManager.activeTrackedWindow else {
            let errorContext = Context(appName: "Unable to add \(appName)", appHash: 0, appTitle: "", appContent: ["error": "Cannot identify context"])
            pendingContextList.insert(errorContext, at: 0)
            return
        }
        let appHash = CFHash(activeTrackedWindow.element)
        let appTitle = activeTrackedWindow.title

        if let existingIndex = pendingContextList.firstIndex(where: { context in
            if case .auto(let autoContext) = context {
                return autoContext.appTitle == appTitle && autoContext.appHash == appHash
            }
            return false
        }) {
            /// For now, we're simply replacing the context.
            /// Later on, we should implement a data aggregator.
            
            let oldContext = pendingContextList[existingIndex]
            
            let newContext = Context(
                appName: appName,
                appHash: appHash,
                appTitle: appTitle,
                appContent: appContent,
                appBundleUrl: AccessibilityNotificationsManager.shared.screenResult.appBundleUrl
            )
            
            if oldContext != newContext {
                ContextWindowsManager.shared.deleteContextItem(item: oldContext)
                pendingContextList[existingIndex] = newContext
            }
            
            cleanupAutoContextTask(windowName: appTitle)
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

        let autoContext = Context(
            appName: appName,
            appHash: appHash,
            appTitle: appTitle,
            appContent: appContent,
            appBundleUrl: AccessibilityNotificationsManager.shared.screenResult.appBundleUrl
        )
        
        pendingContextList.insert(autoContext, at: 0)
        
        cleanupAutoContextTask(windowName: appTitle)
    }
    
    func cleanupAutoContextTask(windowName: String) {
        addAutoContextTasks[windowName]?.cancel()
        addAutoContextTasks.removeValue(forKey: windowName)
    }
    
    func addWindowToContext(
        windowName: String,
        pid: pid_t,
        appBundleUrl: URL?
    ) {
        addAutoContextTasks[windowName]?.cancel()
        
        addAutoContextTasks[windowName] = Task {
            guard let focusedWindow = pid.firstMainWindow
            else {
                await MainActor.run {
                    self.cleanupAutoContextTask(windowName: windowName)
                }
                return
            }
            
            let _ = AccessibilityNotificationsManager.shared.windowsManager.append(
                focusedWindow,
                pid: pid
            )
            
            // No need to clean up `addAutoContextTasks` here, because `fetchAutoContext` ultimately leads to `addAutoContext()` down the stack, which will handle the cleanup.
            AccessibilityNotificationsManager.shared.fetchAutoContext(
                pid: pid,
                state: self,
                customAppBundleUrl: appBundleUrl
            )
        }
    }
    
    func getCurrentWindowDetails() -> (String?, pid_t?, URL?) {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        
        if let currentWindow = windowsManager.activeTrackedWindow,
           let windowPid = currentWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: windowPid)
        {
            let windowName = currentWindow.element.title() ?? currentWindow.element.appName() ?? "Unknown"
            let windowAppBundleUrl = windowApp.bundleURL
            
            return (windowName, windowPid, windowAppBundleUrl)
        } else {
            return (nil, nil, nil)
        }
    }
    
    func setCurrentWindowDetails(
        windowName: String? = nil,
        windowPid: pid_t? = nil,
        windowAppBundleUrl: URL? = nil
    ) {
        self.currentWindowName = windowName
        self.currentWindowPid = windowPid
        self.currentWindowAppBundleUrl = windowAppBundleUrl
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
    //    }
}
