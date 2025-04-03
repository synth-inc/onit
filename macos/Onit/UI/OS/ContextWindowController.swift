//
//  ContextWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import AppKit
import SwiftUI

@MainActor
class ContextWindowController: NSObject, NSWindowDelegate {

    // MARK: - Properties

    private weak var model: OnitModel?
    private let context: Context
    private let contentView: ContextView?
    private var window: NSWindow?
    private var webFileContents: String = ""

    // MARK: - Initializers

    init?(model: OnitModel, context: Context) {
        var title: String
        
        switch context {
        case .auto(let appName, _):
            title = appName
        case .web(let websiteUrl, let websiteTitle, _):
            let websiteUrlDomain = websiteUrl.host() ?? websiteUrl.absoluteString
            title = websiteTitle.isEmpty ? websiteUrlDomain : websiteTitle

            self.webFileContents = "Contents for \(websiteUrlDomain) are still loading."
            
            let websiteContentsUnavailableText = "Website contents not available."
            let pendingContextList = model.getPendingContextList()
            
            let webContextItemIndex = getWebContextItemIndex(
                pendingContextList: pendingContextList,
                comparativeWebUrl: websiteUrl
            )
            
            if let webContextItemIndex = webContextItemIndex,
               pendingContextList.indices.contains(webContextItemIndex)
            {
                let webContextItem = pendingContextList[webContextItemIndex]
                
                if case .web(_, _, let recentWebFileUrl) = webContextItem,
                   let recentWebFileUrl = recentWebFileUrl
                {
                    do {
                        let webFileContents = try String(contentsOf: recentWebFileUrl)
                        
                        let webFileContentsSplit = webFileContents.split(separator: "\n")
                        let splitCount = webFileContentsSplit.count
                        let contents = webFileContentsSplit[2..<splitCount-2].joined(separator: "")

                        self.webFileContents = contents
                    } catch {
                        self.webFileContents = websiteContentsUnavailableText
                    }
                }
            } else {
                self.webFileContents = websiteContentsUnavailableText
            }
        default:
            return nil
        }

        self.model = model
        self.context = context

        self.contentView = ContextView(context: context, webFileContents: self.webFileContents)

        super.init()

        let contentView =
            contentView
            .environment(\.model, model)
            .fixedSize()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = title
        window.isOpaque = false
        window.backgroundColor = NSColor.black
        window.level = .modalPanel
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false

        // TODO: KNA - WIP: Display the stars icon in title's left
        window.representedURL = URL(string: "")
        window.standardWindowButton(.documentIconButton)?.image = .stars

        self.window = window
    }

    // MARK: - Functions

    func showWindow() {
        updateWindowSize()
        positionWindow()
        bringToFront()
    }

    func bringToFront() {
        window?.alphaValue = 1.0
        window?.orderFront(nil)
    }

    func closeWindow() {
        guard let window = window else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 0.0
            },
            completionHandler: {
                window.orderOut(nil)
                window.alphaValue = 1.0
                self.window = nil
            })
    }

    // MARK: - Private Functions

    private func positionWindow() {
        guard let window = window else {
            print("No overlay window found.")
            return
        }

        let mouseLocation = NSEvent.mouseLocation

        guard
            let screen = NSScreen.screens.first(where: {
                NSMouseInRect(mouseLocation, $0.frame, false)
            })
        else {
            print("No screen contains the mouse location.")
            return
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Convert mouse location to local screen coordinates
        let localMouseLocation = NSPoint(
            x: mouseLocation.x - screenFrame.origin.x,
            y: mouseLocation.y - screenFrame.origin.y
        )

        // Adjust mouse Y-coordinate to position the window lower
        let adjustedMouseY = localMouseLocation.y - 15  // Adjust this value as needed

        let overlayWidth = window.frame.width
        let overlayHeight = window.frame.height

        // Calculate the overlay's origin point
        var overlayOriginX = localMouseLocation.x - overlayWidth / 2
        var overlayOriginY = adjustedMouseY - overlayHeight

        // Ensure the overlay doesn't go off-screen horizontally
        overlayOriginX = max(
            visibleFrame.minX - screenFrame.origin.x,
            min(overlayOriginX, visibleFrame.maxX - screenFrame.origin.x - overlayWidth)
        )

        // If the overlay would go off the bottom of the screen, position it above the cursor
        if overlayOriginY < visibleFrame.minY - screenFrame.origin.y {
            overlayOriginY = adjustedMouseY + overlayHeight + 10  // Position above the cursor
        }

        // Convert overlay origin back to global screen coordinates
        let globalOverlayOrigin = NSPoint(
            x: overlayOriginX + screenFrame.origin.x,
            y: overlayOriginY + screenFrame.origin.y
        )

        window.setFrameOrigin(globalOverlayOrigin)
    }

    private func updateWindowSize() {
        guard let window = window else { return }
        guard let contentView = window.contentViewController?.view else { return }

        contentView.layoutSubtreeIfNeeded()
        let contentSize = contentView.fittingSize
        window.setContentSize(contentSize)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        model?.contextWindowControllers.removeValue(forKey: context)
    }

}
