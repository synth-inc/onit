//
//  Model+Tooltip.swift
//  Onit
//
//  Created by Benjamin Sage on 10/29/24.
//

import AppKit
import SwiftUI

extension OnitModel {
  func setTooltip(_ tooltip: Tooltip?, immediate: Bool = false) {
    tooltipTask?.cancel()

    if let tooltip {
      if isTooltipActive {
        resetTooltip(tooltip)
        updateTooltipWindowSize()
        moveTooltip()
        showTooltip = true
        showWindowWithoutAnimation()
      } else {
        tooltipTask = Task {
          try? await Task.sleep(for: .seconds(0.5))
          if Task.isCancelled { return }
          isTooltipActive = true
          setupTooltip(tooltip)
          updateTooltipWindowSize()
          moveTooltip()
          showTooltip = true
          showWindowWithoutAnimation()
        }
      }
    } else {
      tooltipTask = Task {
        try? await Task.sleep(for: .seconds(immediate ? 0 : 0.2))
        if Task.isCancelled { return }
        isTooltipActive = false
        showTooltip = false
        if immediate {
          hideWindowWithoutAnimation()
        } else {
          hideWindowWithAnimation()
        }
      }
    }
  }

  func moveTooltip() {
    guard let tooltipWindow = self.tooltipWindow else {
      print("No tooltip window found.")
      return
    }

    let mouseLocation = NSEvent.mouseLocation

    guard
      let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
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

    // Adjust mouse Y-coordinate to account for the menu bar
    let adjustedMouseY = localMouseLocation.y + 5

    let tooltipWidth = tooltipWindow.frame.width
    let tooltipHeight = tooltipWindow.frame.height

    // Calculate the tooltip's origin point
    var tooltipOriginX = localMouseLocation.x - tooltipWidth / 2
    var tooltipOriginY = adjustedMouseY - tooltipHeight

    // Ensure the tooltip doesn't go off-screen horizontally
    tooltipOriginX = max(
      visibleFrame.minX - screenFrame.origin.x,
      min(tooltipOriginX, visibleFrame.maxX - screenFrame.origin.x - tooltipWidth))

    // If the tooltip would go off the bottom of the screen, position it below the mouse pointer
    if tooltipOriginY < visibleFrame.minY - screenFrame.origin.y {
      tooltipOriginY = adjustedMouseY
    }

    // Convert tooltip origin back to global screen coordinates
    let globalTooltipOrigin = NSPoint(
      x: tooltipOriginX + screenFrame.origin.x,
      y: tooltipOriginY + screenFrame.origin.y
    )

    tooltipWindow.setFrameOrigin(globalTooltipOrigin)
  }

  func convertRectToScreen(rect: CGRect, from view: NSView) -> CGRect {
    guard let window = view.window else {
      return rect
    }

    // Convert rect from view coordinates to window coordinates
    let windowRect = view.convert(rect, to: nil)

    // Convert rect from window coordinates to screen coordinates
    let screenRect = window.convertToScreen(windowRect)

    return screenRect
  }

  func showWindowWithoutAnimation() {
    guard let tooltipWindow = self.tooltipWindow else { return }
    tooltipWindow.alphaValue = 1.0
    tooltipWindow.makeKeyAndOrderFront(nil)
  }

  func hideWindowWithAnimation() {
    guard let tooltipWindow = self.tooltipWindow else { return }

    NSAnimationContext.runAnimationGroup(
      { context in
        context.duration = 0.3  // Adjust duration as needed
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        tooltipWindow.animator().alphaValue = 0.0
      },
      completionHandler: {
        tooltipWindow.orderOut(nil)
        tooltipWindow.alphaValue = 1.0
      })
  }

  func hideWindowWithoutAnimation() {
    guard let tooltipWindow = self.tooltipWindow else { return }
    tooltipWindow.orderOut(nil)
    tooltipWindow.alphaValue = 1.0
  }

  func showWindowWithAnimation() {
    guard let tooltipWindow = self.tooltipWindow else { return }

    tooltipWindow.contentView?.wantsLayer = true
    guard let layer = tooltipWindow.contentView?.layer else { return }

    let oldFrame = layer.frame
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.frame = oldFrame  // Reset frame to keep the layer in the same place

    // Set initial state
    tooltipWindow.alphaValue = 0.0
    tooltipWindow.makeKeyAndOrderFront(nil)

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.3  // Adjust duration as needed
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      tooltipWindow.animator().alphaValue = 1.0
    }

    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
    scaleAnimation.fromValue = 0.95
    scaleAnimation.toValue = 1.0
    scaleAnimation.duration = 0.3  // Match duration with alphaValue animation
    scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

    layer.add(scaleAnimation, forKey: "scaleUp")
    layer.transform = CATransform3DIdentity
  }

  func setupTooltip(_ tooltip: Tooltip) {
    if tooltipWindow == nil {
      let contentView = TooltipView(tooltip: tooltip).fixedSize()
      let hostingController = NSHostingController(rootView: contentView)

      let window = NSWindow(contentViewController: hostingController)
      window.styleMask = [.borderless]
      window.isOpaque = false
      window.backgroundColor = NSColor.clear
      window.level = .floating
      window.hasShadow = true
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

      self.tooltipWindow = window
      tooltipWindow?.orderOut(nil)  // Ensures tooltip is initially hidden

      updateTooltipWindowSize()
    } else {
      resetTooltip(tooltip)
    }
  }

  func resetTooltip(_ tooltip: Tooltip) {
    guard let tooltipWindow = self.tooltipWindow else {
      print("No window available to reset.")
      return
    }

    let content = TooltipView(tooltip: tooltip).fixedSize()
    let newHostingController = NSHostingController(rootView: content)

    tooltipWindow.contentViewController = newHostingController
    tooltipWindow.orderOut(nil)

    updateTooltipWindowSize()
  }

  func updateTooltipWindowSize() {
    guard let tooltipWindow = self.tooltipWindow else { return }
    guard let contentView = tooltipWindow.contentViewController?.view else { return }
    contentView.layoutSubtreeIfNeeded()
    let contentSize = contentView.fittingSize
    tooltipWindow.setContentSize(contentSize)
  }
}
