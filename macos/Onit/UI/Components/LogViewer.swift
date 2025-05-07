import SwiftUI

struct LogViewer: View {
    @State private var logContent: String = ""
    @State private var isLoading: Bool = true
    @State private var showExportPanel: Bool = false
    @State private var exportURL: URL? = nil
    
    private let logFileURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Documents/Onit/Onit.log")
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Log File Viewer")
                    .font(.headline)
                Spacer()
                Button("Download Full Log") {
                    showExportPanel = true
                }
                .disabled(!FileManager.default.fileExists(atPath: logFileURL.path))
            }
            .padding(.bottom, 4)
            
            if isLoading {
                ProgressView("Loading log...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(logContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 300)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .onAppear(perform: loadLog)
        .fileExporter(
            isPresented: $showExportPanel,
            document: LogFileDocument(fileURL: logFileURL),
            contentType: .plainText,
            defaultFilename: "Onit.log"
        ) { result in
            // Optionally handle result
        }
    }
    
    private func loadLog() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let content: String
            if let data = try? Data(contentsOf: logFileURL),
               let text = String(data: data, encoding: .utf8) {
                let lines = text.components(separatedBy: .newlines)
                let lastLines = lines.suffix(5000)
                content = lastLines.joined(separator: "\n")
            } else {
                content = "Log file not found or unreadable."
            }
            DispatchQueue.main.async {
                self.logContent = content
                self.isLoading = false
            }
        }
    }
}

import UniformTypeIdentifiers

struct LogFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        self.fileURL = URL(fileURLWithPath: "")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL, options: FileWrapper.ReadingOptions.withoutMapping)
    }
} 
