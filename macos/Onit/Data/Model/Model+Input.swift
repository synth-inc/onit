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

    func newChat() {
        historyIndex = -1
        currentChat = nil
        currentPrompts = nil
        pendingInstruction = ""
        pendingContextList.removeAll()
        pendingInput = nil
        focusText()
        shrinkContent()
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
