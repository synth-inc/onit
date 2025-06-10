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
    
    @Binding private var searchQuery: String
    @Binding private var currentArrowKeyIndex: Int
    @Binding private var maxArrowKeyIndex: Int
    private let closeContextMenu: () -> Void
    private let showBrowserTabsSubMenu: () -> Void
    
    init(
        searchQuery: Binding<String>,
        currentArrowKeyIndex: Binding<Int>,
        maxArrowKeyIndex: Binding<Int>,
        closeContextMenu: @escaping () -> Void,
        showBrowserTabsSubMenu: @escaping () -> Void
    ) {
        self._searchQuery = searchQuery
        self._currentArrowKeyIndex = currentArrowKeyIndex
        self._maxArrowKeyIndex = maxArrowKeyIndex
        self.closeContextMenu = closeContextMenu
        self.showBrowserTabsSubMenu = showBrowserTabsSubMenu
    }
    
    @State private var isCapturingOpenWindows: Bool = false
    @State private var capturingOpenWindowsTask: Task<Void, Never>? = nil
    @State private var capturedOpenWindows: [CapturedOpenWindow] = []
    
    private let ignoredApps: [String] = ["desktop", "finder"]
    
    private var filteredCapturedOpenWindows: [CapturedOpenWindow] {
        if searchQuery.isEmpty {
            return capturedOpenWindows
        } else {
            return capturedOpenWindows.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    private var foregroundWindowCaptured: Bool {
        return
            windowState.currentWindowName != nil &&
            windowState.currentWindowPid != nil &&
            windowState.currentWindowAppBundleUrl != nil
    }
    
    private var allBrowserTabsButtonIndex: Int {
        return foregroundWindowCaptured ? filteredCapturedOpenWindows.count + 1 : filteredCapturedOpenWindows.count
    }
    
    private var uploadFileButtonIndex: Int {
        return foregroundWindowCaptured ? filteredCapturedOpenWindows.count + 1 : filteredCapturedOpenWindows.count
    }
    
    var body: some View {
        if isCapturingOpenWindows {
            ContextMenuLoading()
        } else {
            Group {
                windowOptions
                actionOptions
            }
            .background {
                returnListener
            }
        }
    }
}

// MARK: - Key Listeners

extension ContextMenuWindows {
    private var returnListener: some View {
        KeyListener(key: .return, modifiers: []) {
            handleReturnKeyPress()
        }
    }
}

// MARK: - Child Components (Windows)

extension ContextMenuWindows {
    @ViewBuilder
    private var currentForegroundWindowButton: some View {
        if let currentWindowName = windowState.currentWindowName,
           let currentWindowPid = windowState.currentWindowPid,
           let currentWindowAppBundleUrl = windowState.currentWindowAppBundleUrl,
           !checkWindowShouldBeIgnored(currentWindowName),
           (searchQuery.isEmpty || currentWindowName.contains(searchQuery))
        {
            let windowContextItem = getWindowContextItem(currentWindowName)
            
            ContextMenuWindowButton(
                isLoadingIntoContext: getIsLoadingWindowIntoContext(currentWindowName),
                selected: currentArrowKeyIndex == 0,
                windowName: currentWindowName,
                windowContextItem: windowContextItem,
                windowIcon: windowState.convertAppBundleUrlToNSImage(currentWindowAppBundleUrl)
            ) {
                windowButtonAction(
                    windowName: currentWindowName,
                    windowPid: currentWindowPid,
                    windowContextItem: windowContextItem
                )
            }
        }
    }
    
    private var capturedOpenWindowsButtons: some View {
        ForEach(filteredCapturedOpenWindows.indices, id: \.self) { index in
            let capturedOpenWindow = filteredCapturedOpenWindows[index]
            let indexOffset = foregroundWindowCaptured ? index + 1 : index
            let selected = currentArrowKeyIndex == indexOffset
            
            let windowContextItem = getWindowContextItem(capturedOpenWindow.name)
            
            ContextMenuWindowButton(
                isLoadingIntoContext: getIsLoadingWindowIntoContext(capturedOpenWindow.name),
                selected: selected,
                windowName: capturedOpenWindow.name,
                windowContextItem: windowContextItem,
                windowIcon: capturedOpenWindow.icon
            ) {
                windowButtonAction(
                    windowName: capturedOpenWindow.name,
                    windowPid: capturedOpenWindow.pid,
                    windowContextItem: windowContextItem
                )
            }
        }
    }
    
    private var allBrowserTabsButton: some View {
        let selected = currentArrowKeyIndex == allBrowserTabsButtonIndex
        
        return TextButton(
            background: selected ? .gray600 : .clear,
            icon: .compass,
            text: "All Browser Tabs..."
        ) {
            showBrowserTabsSubMenu()
        }
    }
    
    private var windowOptions: some View {
        MenuSection(contentTopPadding: 0) {
            VStack(alignment: .leading, spacing: 2) {
                currentForegroundWindowButton // The current foreground window is always the first option.
                capturedOpenWindowsButtons
            }
        }
        .onAppear {
            capturingOpenWindowsTask?.cancel()
            
            capturingOpenWindowsTask = Task {
                capturedOpenWindows = await captureOpenWindows()
                
                await MainActor.run {
                    capturingOpenWindowsTask = nil
                }
            }
        }
        .onDisappear {
            capturingOpenWindowsTask?.cancel()
            capturingOpenWindowsTask = nil
        }
        .onChange(of: uploadFileButtonIndex) { _, new in
            maxArrowKeyIndex = uploadFileButtonIndex
        }
    }
}

// MARK: - Child Components (Actions)

extension ContextMenuWindows {
    private var uploadFileButton: some View {
        let selected = currentArrowKeyIndex == uploadFileButtonIndex
        
        return TextButton(
            background: selected ? .gray600 : .clear,
            icon: .file,
            text: "Upload File"
        ) {
            openFilePicker()
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
    private func openFilePicker() {
        AnalyticsManager.ContextPicker.uploadFilePressed()
        windowState.showFileImporter = true
        closeContextMenu()
    }
    
    private func getWindowContextItem(_ windowName: String) -> Context? {
        return windowState.getPendingContextList().first { context in
            guard case .auto(let autoContext) = context else { return false }
            
            return windowName == autoContext.appTitle || windowName == autoContext.appName
        }
    }
    
    private func getIsLoadingWindowIntoContext(_ windowName: String) -> Bool {
        return windowState.addAutoContextTasks[windowName] != nil
    }
    
    private func removeWindowFromContext(_ contextItem: Context) {
        ContextWindowsManager.shared.deleteContextItem(
            item: contextItem
        )
        windowState.removeContext(context: contextItem)
    }
    
    private func addWindowToContext(
        windowName: String,
        windowPid: pid_t
    ) {
        let appBundleUrl = NSRunningApplication(processIdentifier: windowPid)?.bundleURL
        
        windowState.addWindowToContext(
            windowName: windowName,
            pid: windowPid,
            appBundleUrl: appBundleUrl
        )
    }
    
    private func windowButtonAction(
        windowName: String,
        windowPid: pid_t,
        windowContextItem: Context?
    ) {
        let isLoadingWindowIntoContext = getIsLoadingWindowIntoContext(windowName)
        
        if isLoadingWindowIntoContext {
            windowState.cleanupAutoContextTask(windowName: windowName)
        } else if let contextItem = windowContextItem {
            removeWindowFromContext(contextItem)
        } else {
            addWindowToContext(
                windowName: windowName,
                windowPid: windowPid
            )
        }
    }
    
    private func handleReturnKeyPress() {
        /// Bring this back when implementing in-memory hashmap cache of browser tab contexts.
//        if currentArrowKeyIndex == allBrowserTabsButtonIndex {
//            showBrowserTabsSubMenu()
//        }
        
        if currentArrowKeyIndex == uploadFileButtonIndex {
            openFilePicker()
        } else if foregroundWindowCaptured && currentArrowKeyIndex == 0,
                  let currentWindowName = windowState.currentWindowName,
                  let currentWindowPid = windowState.currentWindowPid
        {
            windowButtonAction(
                windowName: currentWindowName,
                windowPid: currentWindowPid,
                windowContextItem: getWindowContextItem(currentWindowName)
            )
        } else if !filteredCapturedOpenWindows.isEmpty {
            let index = foregroundWindowCaptured ? currentArrowKeyIndex - 1 : currentArrowKeyIndex
            let capturedOpenWindow = filteredCapturedOpenWindows[index]
            
            windowButtonAction(
                windowName: capturedOpenWindow.name,
                windowPid: capturedOpenWindow.pid,
                windowContextItem: getWindowContextItem(capturedOpenWindow.name)
            )
        }
    }
    
    private func checkWindowShouldBeIgnored(_ windowName: String) -> Bool {
        return ignoredApps.contains { ignoredApp in
            windowName.lowercased().contains(ignoredApp)
        }
    }
    
    private func captureOpenWindows() async -> [CapturedOpenWindow] {
        isCapturingOpenWindows = true
        
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        let windowPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
        
        var capturedWindowsList: [CapturedOpenWindow] = []
        
        for pid in windowPids {
            let windows = pid.findTargetWindows()
            
            for window in windows {
                let (windowIcon, windowName) = windowState.getWindowIconAndName(
                    window: window,
                    pid: pid
                )
                
                let notIgnoredApp = !checkWindowShouldBeIgnored(windowName)
                
                // Only capturing valid windows:
                //   1. Has a PID.
                //   2. Isn't the current window (this is handled by `currentForegroundWindowButton`).
                //   3. Not in the list of ignored apps.
                if let windowPid = window.pid(),
                   windowPid != windowState.currentWindowPid,
                   windowName != windowState.currentWindowName,
                   notIgnoredApp
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
        
        isCapturingOpenWindows = false
        return capturedWindowsList
    }
}
