//
//  DevSettingsText.swift
//  Onit
//
//  Created by Loyd Kim on 11/26/25.
//

import SwiftUI

struct DevSettingsText: View {
    var body: some View {
        Text(String.localized("Dev Settings", table: "Settings"))
            .padding(.horizontal, 16)
            .styleText(
                size: 12,
                weight: .regular,
                color: Color.S_2
            )
    }
}
