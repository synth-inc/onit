//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PaperclipButton: View {
    @Environment(\.model) var model

    @State var showFileImporter = false

    var body: some View {
        HStack(spacing: 6) {
            Button {
                showFileImporter = true
            } label: {
                Image(.paperclip)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(3)
            }
            .tooltip(prompt: "Upload file")

            if model.pendingContextList.isEmpty {
                Button {
                    showFileImporter = true
                } label: {
                    Text("Add file")
                        .foregroundStyle(.gray200)
                        .appFont(.medium13)
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handle(result)
        }
    }

    func handle(_ result: Result<[URL], any Error>) {
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
        PaperclipButton()
    }
}
#endif
