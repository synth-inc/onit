//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import Defaults
import SwiftUI

struct ContentView: View {
    @Environment(\.openSettings) var openSettings
    @Environment(\.windowState) private var state
    
    @Default(.mode) var mode
    @Default(.panelWidth) var panelWidth
    @Default(.isRegularApp) var isRegularApp
    
    static let idealWidth: CGFloat = 400
    static let bottomPadding: CGFloat = 0
    
    @State var screenHeight: CGFloat = NSScreen.main?.visibleFrame.height ?? 0

    var maxHeight: CGFloat {
        guard screenHeight != 0 else { return 0 }
        
        return screenHeight - ContentView.bottomPadding
    }
    
    var showFileImporterBinding: Binding<Bool> {
        Binding(
            get: { state.showFileImporter },
            set: { state.showFileImporter = $0 }
        )
    }

    var body: some View {
        HStack(spacing: -TetheredButton.width / 2) {
            if isRegularApp {
                TetheredButton()
            }
            
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if !isRegularApp {
                        Toolbar()
                    } else {
                        Spacer()
                            .frame(height: 38)
                    }
                    PromptDivider()
                    ChatView()
                }
            }
            .trackScreenHeight($screenHeight)
            .frame(minWidth: isRegularApp ? 0 : 325, idealWidth: ContentView.idealWidth, maxHeight: maxHeight)
            .background(Color.black)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.gray600, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .edgesIgnoringSafeArea(.top)
        }
        .buttonStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if isRegularApp {
                    ToolbarAddButton()
                } else {
                    EmptyView()
                }
            }
            ToolbarItem(placement: .automatic) {
                Spacer()
            }
            ToolbarItem(placement: .primaryAction) {
                if isRegularApp {
                    Toolbar()
                } else {
                    EmptyView()
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded({
                    state.handlePanelClicked()
                })
        )
        .gesture(
            DragGesture(minimumDistance: 1)
                .onEnded { value in
                    if let panel = state.panel {
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
            state.addContext(urls: urls)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
