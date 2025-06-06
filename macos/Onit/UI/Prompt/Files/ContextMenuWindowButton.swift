//
//  ContextMenuWindowButton.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuWindowButton: View {
    @Environment(\.windowState) private var windowState
    
    private let windowContextItem: Context?
    private let pid: pid_t
    private let name: String
    private let icon: NSImage?
    
    init(
        windowContextItem: Context?,
        pid: pid_t,
        name: String,
        icon: NSImage? = nil
    ) {
        self.windowContextItem = windowContextItem
        self.pid = pid
        self.name = name
        self.icon = icon
    }
    
    var isLoadingWindowIntoContext: Bool {
        getIsLoadingWindowIntoContext(name)
    }
    
    var body: some View {
        TextButton(
            icon: icon == nil ? .stars : nil,
            iconImage: icon,
            text: name
        ){
            if isLoadingWindowIntoContext {
                LoaderPulse()
            } else if windowContextItem == nil {
                checkEmpty
            } else {
                checkFilled
            }
        } action: {
            if isLoadingWindowIntoContext {
                windowState.cleanupAutoContextTask(windowName: name)
            } else if let contextItem = windowContextItem {
                removeWindowFromContext(contextItem)
            } else {
                addWindowToContext(
                    windowName: name,
                    windowPid: pid
                )
            }
        }
    }
}

// MARK: - Child Components

extension ContextMenuWindowButton {
    private var checkEmpty: some View {
        Circle()
            .frame(width: 14, height: 14)
            .background(.T_8).opacity(0.2)
            .addBorder(
                cornerRadius: 999,
                stroke: .T_7
            )
    }
    
    private var checkFilled: some View {
        Image(.check)
            .addIconStyles(iconSize: 8)
            .frame(width: 14, height: 14)
            .background(.blue400)
            .addBorder(
                cornerRadius: 999,
                stroke: .blue300
            )
    }
}

// MARK: - Private Functions

extension ContextMenuWindowButton {
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
    
    private func removeWindowFromContext(_ contextItem: Context) {
        ContextWindowsManager.shared.deleteContextItem(
            item: contextItem
        )
        windowState.removeContext(context: contextItem)
    }
    
    private func getIsLoadingWindowIntoContext(_ windowName: String) -> Bool {
        return windowState.addAutoContextTasks[windowName] != nil
    }
}
