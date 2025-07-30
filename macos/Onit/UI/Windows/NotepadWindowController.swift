//
//  NotepadWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class NotepadWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Singleton
    
    static let shared = NotepadWindowController()

    // MARK: - Properties
    
    private static let minWidth: CGFloat = 320
    private static let animationDuration: TimeInterval = 0.2

    private var panel: CustomPanel?
    private var windowState: OnitPanelState?
    private var isResizing: Bool = false
    private var originalFrame: NSRect = .zero
    private var width: CGFloat {
        get { return Defaults[.notepadWidth] }
        set { Defaults[.notepadWidth] = Double(newValue) }
    }
    
    class CustomPanel: NSPanel {
        override var canBecomeKey: Bool { true }
    }

    // MARK: - Functions

    func showWindow(windowState: OnitPanelState, response: Response) {
        guard response.isDiffResponse,
              let _ = response.diffArguments,
              let _ = response.diffResult else {
            print("NotepadWindowController: Invalid diff response provided")
            return
        }
        
        self.windowState = windowState
        self.windowState?.addDelegate(self)
        
        let notepadView = NotepadView(
            response: response,
            closeCompletion: closeWindow
        )
        .environment(\.windowState, windowState)
        
        let contentWithResize = ZStack(alignment: .leading) {
            notepadView
            
            ResizeHandle(
                onDrag: { [weak self] deltaX in
                    guard let self = self, let panel = self.panel else { return }

                    self.isResizing = true

                    if self.originalFrame == .zero {
                        self.originalFrame = panel.frame
                    }

                    self.resizePanel(byWidth: deltaX)
                },
                onDragEnded: { [weak self] in
                    guard let self = self else { return }
					
                    self.originalFrame = .zero
                    self.isResizing = false
                }
            )
            .padding(.top, NotepadView.toolbarHeight + 1) // Add 1px for divider height
            .frame(width: 6)
            .frame(maxHeight: .infinity)
        }

        let panelContentView = NSHostingView(rootView: contentWithResize)
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = .black

        if panel == nil {
            let newPanel = CustomPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: 600),
                styleMask: [.fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            newPanel.isOpaque = false
            newPanel.backgroundColor = NSColor.clear
            newPanel.level = .floating
            newPanel.titleVisibility = .hidden
            newPanel.titlebarAppearsTransparent = true
            newPanel.isMovableByWindowBackground = true
            newPanel.delegate = self
            newPanel.hidesOnDeactivate = false

            newPanel.standardWindowButton(.closeButton)?.isHidden = true
            newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            newPanel.standardWindowButton(.zoomButton)?.isHidden = true
            newPanel.isFloatingPanel = true
            
            panel = newPanel
        }
        
        panel?.contentView = panelContentView
        panel?.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        
        if let onitPanel = windowState.panel {
            positionWindow(for: onitPanel)
        } else {
            positionWindowForQuickEdit()
        }
        
        windowState.isDiffViewActive = true
        windowState.responseUsedForDiffView = response
        
        bringToFront()
    }

    func bringToFront() {
        panel?.alphaValue = 1.0
        panel?.orderFront(nil)
        panel?.makeKeyAndOrderFront(nil)
    }

    func closeWindow() {
        guard let panel = panel else { return }

        self.windowState?.removeDelegate(self)

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
            },
            completionHandler: { [weak self] in
                self?.windowState?.isDiffViewActive = false
                panel.orderOut(nil)
                panel.alphaValue = 1.0
            })
    }

    // MARK: - Private Functions
    
    private func resizePanel(byWidth deltaWidth: CGFloat) {
        guard let panel = panel else { return }
        
        let newWidth = width - deltaWidth
        
        if newWidth >= Self.minWidth {
            width = newWidth
            
            let newFrame = NSRect(
                x: originalFrame.maxX - newWidth,
                y: panel.frame.origin.y,
                width: newWidth,
                height: panel.frame.height
            )
                
            panel.setFrame(newFrame, display: true)
        }
    }

    private func positionWindow(for onitPanel: OnitPanel) {
        guard let panel = self.panel else { return }

        var newFrame = onitPanel.frame
        
        newFrame.origin.x = onitPanel.frame.origin.x - width + (TetheredButton.width / 2)
        newFrame.size.width = width

        panel.setFrame(newFrame, display: false, animate: false)
    }
    
    private func positionWindowForQuickEdit() {
        guard let panel = self.panel else { return }
        guard let window = QuickEditManager.shared.getWindow(),
              let screen = window.screen else { return }
        
        let x = screen.visibleFrame.maxX - width
        let y = screen.visibleFrame.minY
        let width = width
        let height = screen.visibleFrame.height
        let newFrame = NSRect(origin: CGPoint(x: x, y: y),
                              size: CGSize(width: width, height: height))

        panel.setFrame(newFrame, display: false, animate: false)
    }
    
    private func repositionForOnitPanel(_ onitPanel: OnitPanel) {
        guard let panel = self.panel else { return }
        
        var newFrame = onitPanel.frame
        newFrame.origin.x = onitPanel.frame.origin.x - width + (TetheredButton.width / 2)
        newFrame.size.width = width
        
        panel.setFrame(newFrame, display: true)
    }
    
    func tempHidePanel(state: OnitPanelState) {
        guard let panel = panel else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            panel.animator().alphaValue = 0.0
        }
    }

    func tempShowPanel(state: OnitPanelState) {
        guard let panel = panel else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            panel.animator().alphaValue = 1.0
        }
    }
 
    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        
    }

}

// MARK: - OnitPanelStateDelegate

extension NotepadWindowController: OnitPanelStateDelegate {

    func panelBecomeKey(state: OnitPanelState) {}
    func panelResignKey(state: OnitPanelState) {}
    func panelStateDidChange(state: OnitPanelState) {
        if !state.panelOpened {
            closeWindow()
        } else {
            if state.hidden && !state.panelWasHidden {
                tempHidePanel(state: state)
            } else if !state.hidden && state.panelWasHidden {
                tempShowPanel(state: state)
            }
        }
    }
    
    func panelFrameDidChange(state: OnitPanelState) {
        guard state.panelOpened, let onitPanel = state.panel else { return }
        
        if state.isWindowDragging {
            panel?.alphaValue = 0.3
        } else {
            panel?.alphaValue = 1.0
        }
        
        repositionForOnitPanel(onitPanel)
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}
