//
//  ContextMenuBrowserTabs.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuBrowserTabs: View {
    private let closeContextMenu: () -> Void
    
    init(closeContextMenu: @escaping () -> Void) {
        self.closeContextMenu = closeContextMenu
    }
    
    @State var isCapturingBrowserTabs: Bool = false
    
    var body: some View {
        if isCapturingBrowserTabs {
            ContextMenuLoading()
        } else {
            ContextMenuSection(contentTopPadding: 0) {
                TextButton(text: "Foo") { print("FOO") }
            }
        }
    }
}
