//
//  FloatingPanel.swift
//  Onit
//
//  Created by Benjamin Sage on 9/30/24.
//

import SwiftUI

class FloatingPanel<Content: View>: NSPanel {
    @Binding var isPresented: Bool

    init(
        view: () -> Content,
        contentRect: NSRect,
        backing: NSWindow.BackingStoreType = .buffered,
        defer flag: Bool = false,
        isPresented: Binding<Bool>
    ) {
        self._isPresented = isPresented

        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView],
            backing: backing,
            defer: flag
        )

        isFloatingPanel = true
        level = .floating

        collectionBehavior.insert(.fullScreenAuxiliary)

        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        isMovableByWindowBackground = true

        hidesOnDeactivate = true

        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        animationBehavior = .utilityWindow

        contentView = NSHostingView(rootView: view()
            .ignoresSafeArea()
            .environment(\.floatingPanel, self))
    }

    override func resignMain() {
        super.resignMain()
        close()
    }

    override func close() {
        super.close()
        isPresented = false
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

}

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
  var floatingPanel: NSPanel? {
    get { self[FloatingPanelKey.self] }
    set { self[FloatingPanelKey.self] = newValue }
  }
}
