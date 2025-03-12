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
    @Default(.isRegularApp) var isRegularApp
    
    static let minWidth: CGFloat = 325
    
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0

    var maxHeight: CGFloat {
        guard screenHeight != 0 else { return 0 }
        
        return screenHeight - 100
    }
    
    var toolbarPaddingTop: CGFloat {
        isRegularApp ? -28 : 0
    }
    
    var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { self.model.showFileImporter },
            set: { self.model.showFileImporter = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Toolbar()
                    .padding(.top, toolbarPaddingTop)
                PromptDivider()
                ChatView()
            }
            .opacity(model.showHistory ? 0 : 1)
            .overlay {
                if model.showHistory {
                    HistoryView()
                }
            }
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .screenHeight(binding: $screenHeight)
        .frame(minWidth: ContentView.minWidth, idealWidth: 400, maxHeight: maxHeight)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
                .edgesIgnoringSafeArea(.top)
        }
        //.edgesIgnoringSafeArea(.top)
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
