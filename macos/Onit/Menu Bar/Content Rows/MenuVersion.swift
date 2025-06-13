//
//  MenuVersion.swift
//  Onit
//
//  Created by Alex on 1/12/25.
//

import SwiftUI

struct MenuVersion: View {
    private var versionText: String {
        let version = Bundle.main.appVersion
        let build = Bundle.main.appBuild
        
        #if BETA
        return "Onit v\(version) (\(build)) - BETA"
        #else
        return "Onit v\(version) (\(build))"
        #endif
    }
    
    var body: some View {
        HStack {
            Text(versionText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.primary.opacity(0.5))
            Spacer()
        }
        .frame(height: 18)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}

#Preview {
    MenuVersion()
}
