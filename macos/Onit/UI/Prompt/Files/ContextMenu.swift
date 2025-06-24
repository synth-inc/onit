//
//  ContextMenu.swift
//  Onit
//
//  Created by Loyd Kim on 6/4/25.
//

import SwiftUI

struct ContextMenu: View {
    @Environment(\.windowState) private var windowState
    
    @State private var searchQuery: String = ""
    @State private var currentArrowKeyIndex: Int = 0
    @State private var maxArrowKeyIndex: Int = 0
    
    private var showBrowserTabsContextMenu: Bool {
        return windowState?.showContextMenuBrowserTabs ?? false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if windowState?.showContextMenu == true {
                MenuList(
                    header: menuHeader,
                    search: MenuList.Search(
                        query: $searchQuery,
                        placeholder: "Search windows, tabs & files"
                    )
                ) {
                    ContextMenuWindows(
                        searchQuery: $searchQuery,
                        currentArrowKeyIndex: $currentArrowKeyIndex,
                        maxArrowKeyIndex: $maxArrowKeyIndex
                    ) {
                        closeContextMenu()
                    } showBrowserTabsSubMenu: {
                        showBrowserTabsSubMenu()
                    }
                }
            }
            
            Button("Close") {
                windowState?.showContextMenuBrowserTabs = false
            }
        }
        .background(Color.gray800)
        .cornerRadius(12)
        .onTapGesture {
            windowState?.showContextMenu = false
        }
        .onChange(of: showBrowserTabsContextMenu) { _, new in
            if new {
                windowState?.showContextMenuBrowserTabs = true
            }
        }
    }
}

// MARK: - Keyboard Arrow Key Listeners

extension ContextMenu {
    private var upListener: some View {
        KeyListener(key: .upArrow, modifiers: []) {
            if currentArrowKeyIndex - 1 < 0 {
                currentArrowKeyIndex = maxArrowKeyIndex
            } else {
                currentArrowKeyIndex -= 1
            }
        }
    }
    
    private var downListener: some View {
        KeyListener(key: .downArrow, modifiers: []) {
            if currentArrowKeyIndex + 1 > maxArrowKeyIndex {
                currentArrowKeyIndex = 0
            } else {
                currentArrowKeyIndex += 1
            }
        }
    }
}

// MARK: - Child Components

extension ContextMenu {
    private var backButton: IconButton {
        IconButton(
            icon: .chevLeft
        ) {
            searchQuery = ""
            windowState?.showContextMenuBrowserTabs = false
        }
    }
    
    private var closeButton: IconButton {
        IconButton(
            icon: .cross,
            iconSize: 10
        ) {
            closeContextMenu()
        }
    }
    
    private var menuHeader: MenuHeader<IconButton> {
        MenuHeader(title: showBrowserTabsContextMenu ? "Browser tabs" : "Add context") {
            showBrowserTabsContextMenu ? backButton : closeButton
        }
    }
}

// MARK: - Private Functions

extension ContextMenu {
    private func closeContextMenu() {
        windowState?.showContextMenu = false
    }
    
    private func showBrowserTabsSubMenu() {
        searchQuery = ""
        windowState?.showContextMenuBrowserTabs = true
    }
}
