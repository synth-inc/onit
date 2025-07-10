//
//  OfflineText.swift
//  Onit
//
//  Created by Loyd Kim on 7/10/25.
//

import SwiftUI

struct OfflineText: View {
    @Environment(\.appState) var appState
    
    var body: some View {
        if !appState.isOnline {
            Text("Offline")
                .styleText(color: .limeGreen)
        }
    }
}
