//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Defaults
import SwiftUI

struct FileRow: View {
    @Environment(\.windowState) var windowState
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var debugManager = DebugManager.shared
    
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    @State private var currentWindowInfo = WindowChangeInfo(
        appBundleUrl: nil,
        windowName: nil,
        pid: nil,
        element: nil,
        trackedWindow: nil
    )
    
    @State private var currentTrackedWindow: TrackedWindow? = nil
    @State private var ocrComparisonResult: OCRComparisonResult? = nil
    @State private var showOCRDetails = false
    
    @State private var windowDelegate: WindowChangeDelegate? = nil
    @State private var windowAlreadyInContext: Bool = false
    
    @State private var addingAutoContext: Bool = false
    
    var accessibilityEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    var windowName: String? {
        if accessibilityEnabled,
           !windowAlreadyInContext,
           let windowName = currentWindowInfo.windowName
        {
            return windowName
        } else {
            return nil
        }
    }
    
    var contextTagText: String {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            return "\(ocrResult.matchPercentage)% \(windowName)"
        } else if let windowName = currentWindowInfo.windowName {
            return windowName
        } else {
            return "Unknown"
        }
    }
    
    var contextTagTextColor: Color {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            // Always use normal text color regardless of OCR result
            return .T_2
        } else {
            return .T_2
        }
    }
    
    var contextTagHoverTextColor: Color {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            // Always use normal hover text color regardless of OCR result
            return .white
        } else {
            return .white
        }
    }
    
    var contextTagBackground: Color {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            if ocrResult.matchPercentage < 50 {
                return .redDisabled
            } else if ocrResult.matchPercentage < 75 {
                return .warningDisabled
            } else {
                return .clear
            }
        } else {
            return .clear
        }
    }
    
    var contextTagHoverBackground: Color {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            if ocrResult.matchPercentage < 50 {
                return .redDisabledHover
            } else if ocrResult.matchPercentage < 75 {
                return .warningDisabledHover
            } else {
                return .clear
            }
        } else {
            return .clear
        }
    }
    
    var contextTagErrorDotColor: Color? {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            if ocrResult.matchPercentage < 50 {
                return .red
            } else if ocrResult.matchPercentage < 75 {
                return .yellow
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var showOCRDetailsLink: Bool {
        if let ocrResult = ocrComparisonResult,
           let windowName = currentWindowInfo.windowName,
           ocrResult.appTitle == windowName {
            return ocrResult.matchPercentage < 75
        }
        return false
    }
    
    var appIcon: (any View)? {
        if let appBundleUrl = currentWindowInfo.appBundleUrl {
            let iconUrl = NSWorkspace.shared.icon(forFile: appBundleUrl.path)
            
            return Image(nsImage: iconUrl)
                .resizable()
                .frame(width: 16, height: 16)
                .cornerRadius(4)
        } else {
            return nil
        }
    }
    
    var contextList: [Context]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FlowLayout(spacing: 6) {
                PaperclipButton(
                    currentWindowBundleUrl: currentWindowInfo.appBundleUrl,
                    currentWindowName: currentWindowInfo.windowName,
                    currentWindowPid: currentWindowInfo.pid
                )
                
                if autoContextFromCurrentWindow,
                   let windowName = windowName
                {
                    ContextTag(
                        text: contextTagText,
                        textColor: contextTagTextColor,
                        hoverTextColor: contextTagHoverTextColor,
                        background: contextTagBackground,
                        hoverBackground: contextTagHoverBackground,
                        hasHoverBorder: true,
                        shouldFadeIn: true,
                        iconBundleURL: currentWindowInfo.appBundleUrl,
                        tooltip: "Add \(windowName) Context",
                        errorDotColor: contextTagErrorDotColor
                    ) {
                        addWindowToContext()
                    }
                }
                
                pendingAutoContextItems
                
                if !contextList.isEmpty {
                    ForEach(contextList, id: \.self) { context in
                        ContextItem(item: context, isEditing: true)
                            .scrollTargetLayout()
                            .contentShape(Rectangle())
                    }
                }
            }
            
            // OCR Details Link
            if showOCRDetailsLink {
                HStack {
                    Button("Details →") {
                        showOCRDetails = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(contextTagErrorDotColor)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            currentWindowInfo = initializeCurrentWindowInfo()
            updateCurrentTrackedWindow()
            
            let delegate = WindowChangeDelegate { windowInfo in
                currentWindowInfo = windowInfo
            }
            
            windowDelegate = delegate
            
            AccessibilityNotificationsManager.shared.addDelegate(delegate)
        }
        .onDisappear {
            cleanUpPendingAutoContextTasks()
            cleanUpWindowDelegateIfExists()
        }
        .onChange(of: currentWindowInfo.windowName) { _, _ in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
            updateCurrentTrackedWindow()
        }
        .onChange(of: debugManager.ocrComparisonResults) { _, newResults in
            updateOCRComparisonResult(from: newResults)
        }
        .onChange(of: contextList) { oldContexts, newContexts in
            windowAlreadyInContext = detectCurrentWindowAlreadyInContext()
        }
        .onChange(of: windowState.addAutoContextTasks) { _, _ in
            if let windowName = currentWindowInfo.windowName,
               let _ = windowState.addAutoContextTasks[windowName]
            {
                windowAlreadyInContext = true
            }
            
            addingAutoContext = !windowState.addAutoContextTasks.isEmpty
        }
        .sheet(isPresented: $showOCRDetails) {
            if let ocrResult = ocrComparisonResult {
                OCRDetailSheet(result: ocrResult)
            }
        }
    }
}

// MARK: - Child Components

extension FileRow {
    private var pendingAutoContextItems: some View {
        ForEach(Array(windowState.addAutoContextTasks.keys), id: \.self) { windowName in
            ContextTag(
                text: windowName,
                background: .clear,
                hoverBackground: .clear,
                isLoading: true,
                iconView: LoaderPulse(),
                removeAction: { deleteAutoContextTask(windowName) }
            )
        }
    }
}

// MARK: - Private Functions

extension FileRow {
    private func initializeCurrentWindowInfo() -> WindowChangeInfo {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        if let trackedWindow = windowsManager.activeTrackedWindow,
           let pid = trackedWindow.element.pid(),
           let windowApp = NSRunningApplication(processIdentifier: pid)
        {
            let windowAppBundleUrl = windowApp.bundleURL
            let windowName = trackedWindow.element.title() ?? trackedWindow.element.appName() ?? nil
            
            return WindowChangeInfo(
                appBundleUrl: windowAppBundleUrl,
                windowName: windowName,
                pid: pid,
                element: trackedWindow.element,
                trackedWindow: trackedWindow
            )
        } else {
            return WindowChangeInfo(
                appBundleUrl: nil,
                windowName: nil,
                pid: nil,
                element: nil,
                trackedWindow: nil
            )
        }
    }
    
    private func updateCurrentTrackedWindow() {
        let windowsManager = AccessibilityNotificationsManager.shared.windowsManager
        currentTrackedWindow = windowsManager.activeTrackedWindow
        updateOCRComparisonResult(from: debugManager.ocrComparisonResults)
    }
    
    private func updateOCRComparisonResult(from results: [OCRComparisonResult]) {
        guard let windowName = currentWindowInfo.windowName,
              let pid = currentWindowInfo.pid else {
            ocrComparisonResult = nil
            return
        }
        
        // Find the most recent OCR result that matches our current window
        ocrComparisonResult = results
            .filter { result in
                // Match by app title and check if it's recent (within last 5 minutes)
                result.appTitle == windowName &&
                Date().timeIntervalSince(result.timestamp) < 300
            }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }
    
    private func detectCurrentWindowAlreadyInContext() -> Bool {
        if let windowName = currentWindowInfo.windowName, !contextList.isEmpty {
            for context in contextList {
                if case .auto(let autoContext) = context {
                    if windowName == autoContext.appTitle {
                        deleteAutoContextTask(windowName)
                        return true
                        
                    }
                }
            }
            
            return false
        } else {
            return false
        }
    }
    
    private func addWindowToContext() {
        if let windowName = currentWindowInfo.windowName,
           let pid = currentWindowInfo.pid,
           let focusedWindow = pid.firstMainWindow
        {
            windowState.addAutoContextTasks[windowName]?.cancel()
            
            windowState.addAutoContextTasks[windowName] = Task {
                let _ = AccessibilityNotificationsManager.shared.windowsManager.append(focusedWindow, pid: pid)
                AccessibilityNotificationsManager.shared.fetchAutoContext(pid: pid, state: windowState)
            }
        }
    }
    
    private func deleteAutoContextTask(_ windowName: String) {
        windowState.addAutoContextTasks[windowName]?.cancel()
        windowState.addAutoContextTasks.removeValue(forKey: windowName)
    }
    
    private func cleanUpPendingAutoContextTasks() {
        for (_, task) in windowState.addAutoContextTasks {
            task.cancel()
        }
        
        windowState.addAutoContextTasks = [:]
    }
    
    private func cleanUpWindowDelegateIfExists() {
        if let delegate = windowDelegate {
            AccessibilityNotificationsManager.shared.removeDelegate(delegate)
        }
    }
}

// MARK: - Test

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif
