//
//  TetheredToAppView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/04/2025.
//

import SwiftUI

struct TetheredToAppView: View {
    @Environment(\.windowState) private var state
    
    private var pid: pid_t? {
        state.trackedWindow?.pid
    }
    
    private var appIcon: NSImage? {
        guard let pid = pid, let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        
        return app.icon
    }
    
    private var appTitle: String? {
        state.trackedWindow?.title
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if let appIcon = appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            }
            
            if let appTitle = appTitle {
                Text(appTitle)
                    .lineLimit(1)
                    .appFont(.medium13)
                    .foregroundColor(.gray200)
            }
        }
    }
}

#Preview {
    TetheredToAppView()
}
