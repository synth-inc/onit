//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import SwiftUI

struct ContentView: View {
    @Environment(\.model) var model
    @Default(.panelWidth) var panelWidth

    var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { self.model.showFileImporter },
            set: { self.model.showFileImporter = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Toolbar()
            PromptDivider()
            ChatView()
        }
        .opacity(model.showHistory ? 0 : 1)
        .overlay {
            if model.showHistory {
                HistoryView()
            }
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .frame(minWidth: 325, idealWidth: 400, maxHeight: NSScreen.main?.visibleFrame.height ?? 0)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onEnded { value in
                    if let panel = model.panel {
                        panelWidth = panel.frame.width
                    }
                }
        )
        .fileImporter(
            isPresented: showFileImporterBinding,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            model.addContext(urls: urls)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

#if DEBUG
    #Preview {
        ModelContainerPreview {
            ContentView()
        }
    }
#endif
