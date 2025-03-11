//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextItem: View {
    @Environment(\.model) var model

    var item: Context
    var isEditing: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            switch item {
            case .auto:
                Button {
                    model.showAutoContextWindow(context: item)
                } label: {
                    contentView
                }
                .tooltip(prompt: "View auto-context file")
            default:
                contentView
            }

            if isEditing {
                xButton
            }
        }
        .padding(3)
        .background(isEditing ? .gray700 : .clear, in: .rect(cornerRadius: 4))
    }

    var contentView: some View {
        HStack(spacing: 0) {
            ContextImage(context: item)

            Spacer()
                .frame(width: 4)

            text
        }
    }

    var text: some View {
        HStack(spacing: 2) {
            Text(name)
                .foregroundStyle(.white)
            if let fileType = item.fileType {
                Text(fileType)
                    .foregroundStyle(.gray200)
            }
        }
        .appFont(.medium13)
    }

    var name: String {
        switch item {
        case .auto(let appName, _):
            // For web content, show a cleaner name
            if appName.starts(with: "Web:") {
                // Extract just the domain part if possible
                let parts = appName.split(separator: ":")
                if parts.count > 1 {
                    return String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return appName
        case .file(let url), .image(let url):
            return url.lastPathComponent
        case .error(_, let error):
            return error.localizedDescription
        case .tooBig:
            return "Upload exceeds model limit"
        }
    }

    var xButton: some View {
        Button {
            model.closeAutoContextWindow(context: item)
            model.removeContext(context: item)
        } label: {
            Color.clear
                .frame(width: 16, height: 16)
                .overlay {
                    Image(.smallCross)
                }
        }
    }
}

#if DEBUG
    #Preview {
        ModelContainerPreview {
            ContextItem(item: .file(URL(fileURLWithPath: "")))
        }
    }
#endif
