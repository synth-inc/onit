//
//  Model+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit

extension OnitModel {
    func addAutoContext() {
        guard FeatureFlagManager.shared.accessibility,
            FeatureFlagManager.shared.accessibilityAutoContext
        else {
            return
        }

        let appName = AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "AutoContext"
        if let errorMessage = AccessibilityNotificationsManager.shared.screenResult.errorMessage {
            let errorContext = Context(appName: "Unable to add \(appName)", appContent: ["error": errorMessage])
            pendingContextList.insert(errorContext, at: 0)
            return
        }

        guard let appContent = AccessibilityNotificationsManager.shared.screenResult.others else {
            let errorContext = Context(appName: "Unable to add \(appName)", appContent: ["error": "Empty text"])
            pendingContextList.insert(errorContext, at: 0)
            return
        }

        /** Prevent duplication */
        let contextDuplicated = pendingContextList.contains { context in
            if case .auto(let contextApp, let contextContent) = context {
                return contextApp == appName && contextContent == appContent
            }
            return false
        }
        guard !contextDuplicated else {
            // TODO: KNA - Notify user for duplicated context
            return
        }

        let autoContext = Context(appName: appName, appContent: appContent)
        pendingContextList.insert(autoContext, at: 0)
    }

    func addContext(urls: [URL]) {
        let contextItems = urls.map(Context.init)
        pendingContextList += contextItems

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
        shrinkContent()
        
        SystemPromptState.shared.shouldShowSelection = false
        SystemPromptState.shared.userSelectedPrompt = false
        let suggestedPrompts = promptSuggestionService?.suggestedPrompts ?? []
        SystemPromptState.shared.shouldShowSystemPrompt = shouldSystemPrompt || !suggestedPrompts.isEmpty
    }

    func shrinkContent() {
        contentHeight = 0
        resizing = true
        Task {
            try? await Task.sleep(for: .seconds(0.01))
            resizing = false
        }
    }

    func removeContext(context: Context) {
        self.pendingContextList.removeAll { $0 == context }
        if case .image(let url) = context {
            uploadTasks[url]?.cancel()
            uploadTasks[url] = nil
            imageUploads[url] = nil
        }
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
