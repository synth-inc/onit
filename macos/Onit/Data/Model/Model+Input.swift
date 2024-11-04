//
//  Model+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit

extension OnitModel {
    func setInput(_ input: Input?) {
        self.input = input
    }

    func addContext(urls: [URL]) {
        let contextItems = urls.map(Context.init)
        context += contextItems
        tryToUpload(contextItems)
    }

    func newPrompt() {
        historyIndex = -1
        instructions = ""
        input = nil
        prompt = nil
        generationState = .idle
        focusText()
    }

    func removeContext(context: Context) {
        self.context.removeAll { $0 == context }
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

    var remoteImages: [URL] {
        get async {
            var images: [URL] = []
            for task in uploadTasks.values {
                if let url = await task.value {
                    images.append(url)
                }
            }
            return images
        }
    }
}
