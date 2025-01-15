//
//  Model+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit

extension OnitModel {
    func addContext(urls: [URL]) {
        let contextItems = urls.map(Context.init)
        context += contextItems
        if preferences.mode == .remote {
            tryToUpload(contextItems)
        }
    }

    func addContext(images: [NSImage]) {
        let tempDirectory = FileManager.default.temporaryDirectory

        var imageURLs: [URL] = []
        for image in images {
            let uniqueFileName = UUID().uuidString + ".png"
            let fileURL = tempDirectory.appendingPathComponent(uniqueFileName)

            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
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

    func newPrompt() {
        historyIndex = -1
        instructions = ""
        prompt = nil
        generationState = .idle
        focusText()
        youSaid = nil
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
    
    var localImages: [URL] {
        get async {
            var images: [URL] = []
            for item in context {
                if case .image(let url) = item {
                    images.append(url)
                }
            }
            return images
        }
    }

    func updateYouSaid(text: String) -> String {
        guard let youSaid else {
            youSaid = text
            return text
        }
        let response = youSaid + ", " + text
        self.youSaid = response
        return response
    }
}
