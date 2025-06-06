//
//  ContextMenuWindows.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct CapturedOpenWindow: Identifiable {
    let id = UUID()
    let pid: pid_t
    let name: String
    let icon: NSImage?
    
    init(
        pid: pid_t,
        name: String,
        icon: NSImage? = nil
    ) {
        self.pid = pid
        self.name = name
        self.icon = icon
    }
}

// MARK: - Main Component

struct ContextMenuWindows: View {
    @Environment(\.windowState) private var windowState
    
    private let closeContextMenu: () -> Void
    private let showBrowserTabsSubMenu: () -> Void
    
    init(
        closeContextMenu: @escaping () -> Void,
        showBrowserTabsSubMenu: @escaping () -> Void
    ) {
        self.closeContextMenu = closeContextMenu
        self.showBrowserTabsSubMenu = showBrowserTabsSubMenu
    }
    
    @State private var isCapturingOpenWindows: Bool = false
    @State private var capturingOpenWindowsTask: Task<Void, Never>? = nil
    @State private var capturedOpenWindows: [CapturedOpenWindow] = []
    
    var body: some View {
        if isCapturingOpenWindows {
            ContextMenuLoading()
        } else {
            windowOptions
            actionOptions
        }
    }
}

// MARK: - Child Components (Windows)

extension ContextMenuWindows {
    @ViewBuilder
    private var currentForegroundWindowButton: some View {
        if let currentWindowName = windowState.currentWindowName,
           let currentWindowPid = windowState.currentWindowPid,
           let currentWindowAppBundleUrl = windowState.currentWindowAppBundleUrl
        {
            ContextMenuWindowButton(
                windowContextItem: getWindowContextItem(currentWindowName),
                pid: currentWindowPid,
                name: currentWindowName,
                icon: convertAppBundleUrlToNSImage(currentWindowAppBundleUrl)
            )
        }
    }
    
    private var allBrowserTabsButton: some View {
        TextButton(icon: .compass, text: "All Browser Tabs...") {
            showBrowserTabsSubMenu()
        }
    }
    
    private var windowOptions: some View {
        MenuSection(contentTopPadding: 0) {
            VStack(alignment: .leading, spacing: 2) {
                // The current foreground window is always the first option.
                currentForegroundWindowButton
                
                ForEach(capturedOpenWindows) { capturedOpenWindow in
                    ContextMenuWindowButton(
                        windowContextItem: getWindowContextItem(capturedOpenWindow.name),
                        pid: capturedOpenWindow.pid,
                        name: capturedOpenWindow.name,
                        icon: capturedOpenWindow.icon
                    )
                }
                
                allBrowserTabsButton
            }
        }
        .onAppear {
            capturingOpenWindowsTask?.cancel()
            isCapturingOpenWindows = true
            
            capturingOpenWindowsTask = Task {
                capturedOpenWindows = await captureOpenWindows()
            }
            
            capturingOpenWindowsTask = nil
            isCapturingOpenWindows = false
        }
        .onDisappear {
            capturingOpenWindowsTask?.cancel()
            capturingOpenWindowsTask = nil
        }
    }
}

// MARK: - Child Components (Actions)

extension ContextMenuWindows {
    private var uploadFileButton: some View {
        TextButton(icon: .file, text: "Upload File") {
            AnalyticsManager.ContextPicker.uploadFilePressed()
            windowState.showFileImporter = true
            closeContextMenu()
        }
    }
    
    private var actionOptions: some View {
        MenuSection(showTopBorder: true) {
            VStack(alignment: .leading, spacing: 2) {
                uploadFileButton
            }
        }
    }
}

// MARK: - Private Functions

extension ContextMenuWindows {
    private func convertAppBundleUrlToNSImage(_ appBundleUrl: URL) -> NSImage {
        return NSWorkspace.shared.icon(forFile: appBundleUrl.path)
    }
    
    private func getWindowIconAndName(window: AXUIElement, pid: pid_t) -> (NSImage?, String) {
        var windowIcon: NSImage? = nil
        
        let windowApp = NSRunningApplication(processIdentifier: pid)
        
        if let app = windowApp,
           let appBundleUrl = app.bundleURL
        {
            windowIcon = convertAppBundleUrlToNSImage(appBundleUrl)
        }
        
        let windowName = window.title() ?? window.appName() ?? windowApp?.localizedName ?? "Unknown"
        
        return (windowIcon, windowName)
    }
    
    private func captureOpenWindows() async -> [CapturedOpenWindow] {
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        let windowPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
        
        var capturedWindowsList: [CapturedOpenWindow] = []
        
        for pid in windowPids {
            let windows = pid.findTargetWindows()
            
            for window in windows {
                let (windowIcon, windowName) = getWindowIconAndName(
                    window: window,
                    pid: pid
                )
                
                // Only capturing valid windows:
                //   1. Has a PID.
                //   2. Isn't the current window.
                if let windowPid = window.pid(),
                   windowPid != windowState.currentWindowPid,
                   windowName != windowState.currentWindowName
                {
                    capturedWindowsList.append(
                        CapturedOpenWindow(
                            pid: windowPid,
                            name: windowName,
                            icon: windowIcon
                        )
                    )
                }
            }
        }
        
        return capturedWindowsList
    }
    
    private func getWindowContextItem(_ windowName: String) -> Context? {
        return windowState.getPendingContextList().first { context in
            guard case .auto(let autoContext) = context else { return false }
            
            return windowName == autoContext.appTitle || windowName == autoContext.appName
        }
    }
}
