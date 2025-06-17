//
//  ContextMenuWindows.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct CapturedWindow: Identifiable {
    let id = UUID()
    let trackedWindow: TrackedWindow
    
    init(trackedWindow: TrackedWindow) {
        self.trackedWindow = trackedWindow
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
    
    @State private var isCapturingWindows: Bool = false
    @State private var capturingWindowsTask: Task<Void, Never>? = nil
    @State private var capturedWindows: [CapturedWindow] = []
    
    private let ignoredApps: [String] = ["desktop", "finder"]
    
    private var filteredCapturedWindows: [CapturedWindow] {
        if searchQuery.isEmpty {
            return capturedWindows
        } else {
            return capturedWindows.filter { capturedWindow in
                let name = WindowHelpers.getWindowName(window: capturedWindow.trackedWindow.element)
                return name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    private var foregroundWindowCaptured: Bool {
        return windowState.foregroundWindow != nil
    }
    
    private var allBrowserTabsButtonIndex: Int {
        return foregroundWindowCaptured ? filteredCapturedWindows.count + 1 : filteredCapturedWindows.count
    }
    
    private var uploadFileButtonIndex: Int {
        // This should be updated to be +2, +1 when bringing the browser tab button back in.
        return foregroundWindowCaptured ? filteredCapturedWindows.count + 1 : filteredCapturedWindows.count
    }
    
    var body: some View {
        if isCapturingWindows {
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
        if let foregroundWindow = windowState.foregroundWindow {
            let foregroundWindowName = WindowHelpers.getWindowName(window: foregroundWindow.element)
            let doNotIgnoreWindow = !checkWindowShouldBeIgnored(foregroundWindowName)
            let currentWindowIsInFilter = (searchQuery.isEmpty || foregroundWindowName.contains(searchQuery))
            let showCurrentWindowButton = doNotIgnoreWindow && currentWindowIsInFilter
            
            if showCurrentWindowButton {
                let windowContextItem = getWindowContextItem(
                    uniqueWindowIdentifier: foregroundWindow.hash,
                    windowName: foregroundWindowName
                )
                
                ContextMenuWindowButton(
                    isLoadingIntoContext: getIsLoadingWindowIntoContext(foregroundWindow.hash),
                    selected: currentArrowKeyIndex == 0,
                    trackedWindow: foregroundWindow,
                    windowContextItem: windowContextItem
                ) {
                    windowButtonAction(
                        trackedWindow: foregroundWindow
                    )
                }
            }
        }
    }
    
    private var capturedOpenWindowsButtons: some View {
        ForEach(filteredCapturedWindows.indices, id: \.self) { index in
            let capturedWindow = filteredCapturedWindows[index]
            let indexOffset = foregroundWindowCaptured ? index + 1 : index
            let selected = currentArrowKeyIndex == indexOffset
             
            let uniqueWindowIdentifier = capturedWindow.trackedWindow.hash
            let windowName = WindowHelpers.getWindowName(window: capturedWindow.trackedWindow.element)
            
            let windowContextItem = getWindowContextItem(
                uniqueWindowIdentifier: uniqueWindowIdentifier,
                windowName: windowName
            )
            
            ContextMenuWindowButton(
                isLoadingIntoContext: getIsLoadingWindowIntoContext(uniqueWindowIdentifier),
                selected: selected,
                trackedWindow: capturedWindow.trackedWindow,
                windowContextItem: windowContextItem,
            ) {
                windowButtonAction(
                    trackedWindow: capturedWindow.trackedWindow
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
        .addAnimation(dependency: selected)
    }
    
    private var windowOptions: some View {
        MenuSection(contentTopPadding: 0) {
            VStack(alignment: .leading, spacing: 2) {
                currentForegroundWindowButton // The current foreground window is always the first option.
                capturedOpenWindowsButtons
            }
        }
        .onAppear {
            capturingWindowsTask?.cancel()
            
            capturingWindowsTask = Task {
                capturedWindows = await captureOpenWindows()
                
                await MainActor.run {
                    capturingWindowsTask = nil
                }
            }
        }
        .onDisappear {
            capturingWindowsTask?.cancel()
            capturingWindowsTask = nil
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
        .addAnimation(dependency: selected)
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
    
    private func getWindowContextItem(
        uniqueWindowIdentifier: UInt,
        windowName: String
    ) -> Context? {
        return windowState.getPendingContextList().first { context in
            guard case .auto(let autoContext) = context else { return false }
            
            let hashesMatch = uniqueWindowIdentifier == autoContext.appHash
            let namesMatch = windowName == autoContext.appTitle
            return hashesMatch && namesMatch
        }
    }
    
    private func getIsLoadingWindowIntoContext(_ uniqueWindowIdentifier: UInt) -> Bool {
        return windowState.windowContextTasks[uniqueWindowIdentifier] != nil
    }
    
    private func removeWindowFromContext(_ contextItem: Context) {
        ContextWindowsManager.shared.deleteContextItem(
            item: contextItem
        )
        windowState.removeContext(context: contextItem)
    }
    
    private func windowButtonAction(trackedWindow: TrackedWindow) {
        let isLoadingWindowIntoContext = getIsLoadingWindowIntoContext(trackedWindow.hash)
        let windowContextItem = getWindowContextItem(
            uniqueWindowIdentifier: trackedWindow.hash,
            windowName: WindowHelpers.getWindowName(window: trackedWindow.element)
        )
        
        if isLoadingWindowIntoContext {
            windowState.cleanupWindowContextTask(
                uniqueWindowIdentifier: trackedWindow.hash
            )
        } else if let contextItem = windowContextItem {
            removeWindowFromContext(contextItem)
        } else {
            windowState.addWindowToContext(window: trackedWindow.element)
        }
    }
    
    private func handleReturnKeyPress() {
        /// Bring this back when implementing in-memory hashmap cache of browser tab contexts.
//        if currentArrowKeyIndex == allBrowserTabsButtonIndex {
//            showBrowserTabsSubMenu()
//        }
        
        if currentArrowKeyIndex == uploadFileButtonIndex {
            openFilePicker()
        } else if let foregroundWindow = windowState.foregroundWindow,
                  foregroundWindowCaptured && currentArrowKeyIndex == 0
        {
            windowButtonAction(
                trackedWindow: foregroundWindow
            )
        } else if !filteredCapturedWindows.isEmpty {
            let index = foregroundWindowCaptured ? currentArrowKeyIndex - 1 : currentArrowKeyIndex
            let capturedWindow = filteredCapturedWindows[index]
            
            windowButtonAction(
                trackedWindow: capturedWindow.trackedWindow
            )
        }
    }
    
    private func checkWindowShouldBeIgnored(_ windowName: String) -> Bool {
        return ignoredApps.contains { ignoredApp in
            windowName.lowercased().contains(ignoredApp)
        }
    }
    
    private func captureOpenWindows() async -> [CapturedWindow] {
        isCapturingWindows = true
        
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        let windowPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
        
        var capturedOpenWindows: [CapturedWindow] = []
        
        for pid in windowPids {
            let windows = pid.findTargetWindows()
            
            for window in windows {
                let trackedWindow = TrackedWindow(
                    element: window,
                    pid: pid,
                    hash: CFHash(window),
                    title: WindowHelpers.getWindowName(window: window)
                )
                
                AccessibilityNotificationsManager.shared.windowsManager.addToTrackedWindows(trackedWindow)
                
                if let foregroundWindow = windowState.foregroundWindow {
                    if trackedWindow != foregroundWindow {
                        capturedOpenWindows.append(
                            CapturedWindow(trackedWindow: trackedWindow)
                        )
                    }
                } else {
                    capturedOpenWindows.append(
                        CapturedWindow(trackedWindow: trackedWindow)
                    )
                }
            }
        }
        
        isCapturingWindows = false
        return capturedOpenWindows
    }
}
