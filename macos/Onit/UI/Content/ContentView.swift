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
    @Default(.isPanelExpanded) var isPanelExpanded: Bool
    
    static let idealWidth: CGFloat = 400
    static let bottomPadding: CGFloat = 100
    
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0
    @State private var contentHeight: CGFloat = 0

//    var maxHeight: CGFloat {
//        guard screenHeight != 0 else { return 0 }
//        return screenHeight - ContentView.bottomPadding
//    }
    
    private var maxHeight: CGFloat {
        guard !model.resizing, screenHeight != 0 else { return 0 }
        
        let availableHeight =
            screenHeight -
            model.headerHeight -
            model.inputHeight -
            model.setUpHeight -
            model.systemPromptHeight -
            ContentView.bottomPadding
        
        return availableHeight
    }
    
    private var appHeight: CGFloat {
        return isRegularApp ?
            maxHeight :
            (isPanelExpanded ? maxHeight : min(contentHeight, maxHeight))
    }
    
    private var toolbarPaddingTop: CGFloat {
        isRegularApp ? -28 : 0
    }
    
    private var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { self.model.showFileImporter },
            set: { self.model.showFileImporter = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Toolbar()
                    .padding(.top, toolbarPaddingTop)
                
                PromptDivider()
                
                ChatView()
            }
        }
        .trackScreenHeight($screenHeight)
        .frame(
            minWidth: 325,
            idealWidth: ContentView.idealWidth,
            maxHeight: maxHeight
        )
        .frame(height: appHeight)
        .background(Color.black)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 1)
                .edgesIgnoringSafeArea(.top)
        }
        .buttonStyle(PlainButtonStyle())
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
