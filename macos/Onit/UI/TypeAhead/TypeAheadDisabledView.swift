//
//  TypeAheadDisabledView.swift
//  Onit
//
//  Created by Kévin Naudin on 21/02/2025.
//

import SwiftUI

struct TypeAheadDisabledView: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    let reason: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(.circleCheck)
                .resizable()
                .foregroundColor(.blue300)
                .frame(width: 14, height: 14)
            Text(reason)
                .font(.system(size: 12, weight: .medium))
            Button {
                appState.setSettingsTab(tab: .typeahead)
                openSettings()
            } label: {
                Image(.settingsCog)
                    .resizable()
                    .foregroundColor(.gray200)
                    .frame(width: 20, height: 20)
            }
            .padding(.leading, 4)
            .buttonStyle(.plain)
        }
        .frame(minHeight: 30)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray500)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    TypeAheadDisabledView(reason: "Auto-complete paused")
}
