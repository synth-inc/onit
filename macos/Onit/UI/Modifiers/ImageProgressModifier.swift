//
//  ImageProgress.swift
//  Onit
//
//  Created by Benjamin Sage on 10/29/24.
//

import SwiftUI

struct ImageProgressModifier: ViewModifier {
    @Environment(\.windowState) private var state

    var url: URL

    var progress: Int? {
        if let progress = state?.imageUploads[url] {
            switch progress {
            case .completed:
                return 100
            case .progress(let progress):
                return Int(progress * 100)
            }
        } else {
            return nil
        }
    }

    var done: Bool {
        if let progress = state?.imageUploads[url] {
            switch progress {
            case .completed:
                return true
            case .progress:
                return false
            }
        } else {
            return false
        }
    }

    func body(content: Content) -> some View {
        if let progress {
            content
                .loadingOverlay(progress, done: done)
        } else {
            content
        }
    }
}

extension View {
    func imageProgress(url: URL) -> some View {
        modifier(ImageProgressModifier(url: url))
    }
}

#if DEBUG
    #Preview {
        Color.red500
            .modifier(ImageProgressModifier(url: .applicationDirectory))
    }
#endif
