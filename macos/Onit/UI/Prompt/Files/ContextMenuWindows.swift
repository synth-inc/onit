//
//  ContextMenuWindows.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct CapturedOpenWindow: Identifiable {
    let id = UUID()
    let window: AXUIElement
    
    init(window: AXUIElement) {
        self.window = window
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
            return capturedOpenWindows.filter { capturedWindow in
                let name = windowState.getWindowName(window: capturedWindow.window)
                return name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    private var foregroundWindowCaptured: Bool {
        return windowState.foregroundWindow != nil
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
        if let foregroundWindow = windowState.foregroundWindow {
            let foregroundWindowName = windowState.getWindowName(window: foregroundWindow.element)
            let doNotIgnoreWindow = !checkWindowShouldBeIgnored(foregroundWindowName)
            let currentWindowIsInFilter = (searchQuery.isEmpty || foregroundWindowName.contains(searchQuery))
            let showCurrentWindowButton = doNotIgnoreWindow && currentWindowIsInFilter
            
            if showCurrentWindowButton {
                let windowContextItem = getWindowContextItem(foregroundWindow.hash)
                
                ContextMenuWindowButton(
                    isLoadingIntoContext: getIsLoadingWindowIntoContext(foregroundWindow.hash),
                    selected: currentArrowKeyIndex == 0,
                    window: foregroundWindow.element,
                    windowContextItem: windowContextItem
                ) {
                    windowButtonAction(
                        window: foregroundWindow.element,
                        uniqueWindowIdentifier: foregroundWindow.hash,
                        windowContextItem: windowContextItem
                    )
                }
            }
        }
    }
    
    private var capturedOpenWindowsButtons: some View {
        ForEach(filteredCapturedOpenWindows.indices, id: \.self) { index in
            let capturedOpenWindow = filteredCapturedOpenWindows[index]
            let indexOffset = foregroundWindowCaptured ? index + 1 : index
            let selected = currentArrowKeyIndex == indexOffset
            
            let uniqueWindowIdentifier = CFHash(capturedOpenWindow.window) // Placeholder. Still need to work this out.
            let windowContextItem = getWindowContextItem(uniqueWindowIdentifier)
            
            ContextMenuWindowButton(
                isLoadingIntoContext: getIsLoadingWindowIntoContext(uniqueWindowIdentifier),
                selected: selected,
                window: capturedOpenWindow.window,
                windowContextItem: windowContextItem,
            ) {
                windowButtonAction(
                    window: capturedOpenWindow.window,
                    uniqueWindowIdentifier: uniqueWindowIdentifier,
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
    
    private func getWindowContextItem(_ uniqueWindowIdentifier: UInt) -> Context? {
        return windowState.getPendingContextList().first { context in
            guard case .auto(let autoContext) = context else { return false }
            
            return uniqueWindowIdentifier == autoContext.appHash
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
    
    private func windowButtonAction(
        window: AXUIElement,
        uniqueWindowIdentifier: UInt,
        windowContextItem: Context?
    ) {
//        let isLoadingWindowIntoContext = getIsLoadingWindowIntoContext(uniqueWindowIdentifier)
//        
//        if isLoadingWindowIntoContext {
//            windowState.cleanupWindowContextTask(
//                uniqueWindowIdentifier: uniqueWindowIdentifier
//            )
//        }
        
        if let contextItem = windowContextItem {
            removeWindowFromContext(contextItem)
        } else {
            windowState.addWindowToContext(window: window)
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
                window: foregroundWindow.element,
                uniqueWindowIdentifier: foregroundWindow.hash,
                windowContextItem: getWindowContextItem(foregroundWindow.hash)
            )
        } else if !filteredCapturedOpenWindows.isEmpty {
            let index = foregroundWindowCaptured ? currentArrowKeyIndex - 1 : currentArrowKeyIndex
            let capturedOpenWindow = filteredCapturedOpenWindows[index]
            
            windowButtonAction(
                window: capturedOpenWindow.window,
                uniqueWindowIdentifier: CFHash(capturedOpenWindow.window), // Placeholder. Still need to work this out.
                windowContextItem: getWindowContextItem(CFHash(capturedOpenWindow.window))
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
                if let foregroundWindow = windowState.foregroundWindow {
                    if window != foregroundWindow.element {
                        capturedWindowsList.append(
                            CapturedOpenWindow(window: window)
                        )
                    }
                } else {
                    capturedWindowsList.append(
                        CapturedOpenWindow(window: window)
                    )
                }
            }
        }
        
        isCapturingOpenWindows = false
        return capturedWindowsList
    }
}
