//
//  ContextMenu.swift
//  Onit
//
//  Created by Loyd Kim on 6/4/25.
//

import SwiftUI

struct ContextMenu: View {
    @Environment(\.windowState) private var windowState
    
    private let showContextMenu: Binding<Bool>
    
    init(_ showContextMenu: Binding<Bool>) {
        self.showContextMenu = showContextMenu
    }
    
    @State private var searchQuery: String = ""
    @State private var showBrowserTabs: Bool = false
    
    var body: some View {
        MenuList(
            header: menuHeader,
            search: MenuList.Search(
                query: $searchQuery,
                placeholder: "Search windows, tabs & files"
            )
        ) {
            if showBrowserTabs {
                ContextMenuBrowserTabs {
                    closeContextMenu()
                }
            } else {
                ContextMenuWindows {
                    closeContextMenu()
                } showBrowserTabsSubMenu: {
                    showBrowserTabsSubMenu()
                }
            }
        }
    }
}

// MARK: - Child Components

extension ContextMenu {
    private var backButton: IconButton {
        IconButton(
            icon: .chevLeft,
            action: {
                searchQuery = ""
                showBrowserTabs = false
            }
        )
    }
    
    private var closeButton: IconButton {
        IconButton(
            icon: .cross,
            iconSize: 10,
            action: closeContextMenu
        )
    }
    
    private var menuHeader: MenuHeader<IconButton> {
        MenuHeader(title: showBrowserTabs ? "Browser tabs" : "Add context") {
            showBrowserTabs ? backButton : closeButton
        }
    }
}

// MARK: - Private Functions

extension ContextMenu {
    private func closeContextMenu() {
        showContextMenu.wrappedValue = false
    }
    
    private func showBrowserTabsSubMenu() {
        searchQuery = ""
        showBrowserTabs = true
    }
}
