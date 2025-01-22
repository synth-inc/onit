import XCTest
@testable import Onit

final class FileUploadTests: XCTestCase {
    var fetchingClient: FetchingClient!
    let testBundle = Bundle(for: FileUploadTests.self)
    
    override func setUp() {
        super.setUp()
        fetchingClient = FetchingClient()
    }
    
    override func tearDown() {
        fetchingClient = nil
        super.tearDown()
    }
    
    // MARK: - Helper Functions
    
    private func createTestFile(_ content: String, withExtension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func createTestImage(size: CGSize, color: NSColor) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            try! pngData.write(to: fileURL)
        }
        
        return fileURL
    }
    
    // MARK: - Tests for Supported Image Types
    
    func testPNGUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        var progressReceived = false
        var completed = false
        
        for await progress in fetchingClient.upload(image: imageURL) {
            switch progress {
            case .progress(let value):
                progressReceived = true
                XCTAssertGreaterThanOrEqual(value, 0)
                XCTAssertLessThanOrEqual(value, 1)
            case .completed(let url):
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".png"))
            }
        }
        
        XCTAssertTrue(progressReceived, "Should receive progress updates")
        XCTAssertTrue(completed, "Upload should complete")
    }
    
    func testJPEGUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 100, height: 100), color: .blue)
        let jpegURL = imageURL.deletingPathExtension().appendingPathExtension("jpeg")
        try! FileManager.default.moveItem(at: imageURL, to: jpegURL)
        
        var completed = false
        
        for await progress in fetchingClient.upload(image: jpegURL) {
            if case .completed(let url) = progress {
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".jpeg"))
            }
        }
        
        XCTAssertTrue(completed, "Upload should complete")
    }
    
    func testGIFUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 100, height: 100), color: .green)
        let gifURL = imageURL.deletingPathExtension().appendingPathExtension("gif")
        try! FileManager.default.moveItem(at: imageURL, to: gifURL)
        
        var completed = false
        
        for await progress in fetchingClient.upload(image: gifURL) {
            if case .completed(let url) = progress {
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".gif"))
            }
        }
        
        XCTAssertTrue(completed, "Upload should complete")
    }
    
    func testWEBPUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 100, height: 100), color: .yellow)
        let webpURL = imageURL.deletingPathExtension().appendingPathExtension("webp")
        try! FileManager.default.moveItem(at: imageURL, to: webpURL)
        
        var completed = false
        
        for await progress in fetchingClient.upload(image: webpURL) {
            if case .completed(let url) = progress {
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".webp"))
            }
        }
        
        XCTAssertTrue(completed, "Upload should complete")
    }
    
    // MARK: - Tests for Unsupported File Types
    
    func testUnsupportedFileTypes() async throws {
        let unsupportedExtensions = ["txt", "pdf", "doc", "docx", "mp4", "mov", "avi"]
        
        for ext in unsupportedExtensions {
            let fileURL = createTestFile("Test content", withExtension: ext)
            var receivedProgress = false
            
            for await progress in fetchingClient.upload(image: fileURL) {
                receivedProgress = true
            }
            
            XCTAssertFalse(receivedProgress, "Should not process unsupported file type: .\(ext)")
        }
    }
    
    // MARK: - Error Cases
    
    func testInvalidURL() async throws {
        let invalidURL = URL(string: "invalid://test.png")!
        var receivedProgress = false
        
        for await _ in fetchingClient.upload(image: invalidURL) {
            receivedProgress = true
        }
        
        XCTAssertFalse(receivedProgress, "Should not process invalid URL")
    }
    
    func testNonexistentFile() async throws {
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/path/image.png")
        var receivedProgress = false
        
        for await _ in fetchingClient.upload(image: nonexistentURL) {
            receivedProgress = true
        }
        
        XCTAssertFalse(receivedProgress, "Should not process nonexistent file")
    }
    
    // MARK: - Edge Cases
    
    func testLargeImageUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 5000, height: 5000), color: .purple)
        var progressReceived = false
        var completed = false
        
        for await progress in fetchingClient.upload(image: imageURL) {
            switch progress {
            case .progress(let value):
                progressReceived = true
                XCTAssertGreaterThanOrEqual(value, 0)
                XCTAssertLessThanOrEqual(value, 1)
            case .completed(let url):
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".png"))
            }
        }
        
        XCTAssertTrue(progressReceived, "Should receive progress updates for large file")
        XCTAssertTrue(completed, "Large file upload should complete")
    }
    
    func testEmptyImageUpload() async throws {
        let imageURL = createTestImage(size: CGSize(width: 0, height: 0), color: .clear)
        var completed = false
        
        for await progress in fetchingClient.upload(image: imageURL) {
            if case .completed(let url) = progress {
                completed = true
                XCTAssertTrue(url.absoluteString.contains(".png"))
            }
        }
        
        XCTAssertTrue(completed, "Empty file upload should complete")
    }
    
    func testConcurrentUploads() async throws {
        let imageURLs = (0..<5).map { _ in
            createTestImage(size: CGSize(width: 100, height: 100), color: .red)
        }
        
        async let uploads = imageURLs.map { url in
            var completed = false
            for await progress in fetchingClient.upload(image: url) {
                if case .completed = progress {
                    completed = true
                }
            }
            return completed
        }
        
        let results = try await uploads
        XCTAssertTrue(results.allSatisfy { $0 }, "All concurrent uploads should complete")
    }
}