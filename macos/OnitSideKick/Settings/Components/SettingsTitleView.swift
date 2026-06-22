//
//  SettingsTitleView.swift
//  Onit
//
//  Created by Loyd Kim on 2/25/26.
//

import SwiftUI

struct SettingsTitleView: View {
    // MARK: - Properies
    
    let text: String
    
    // MARK: - Body
    
    var body: some View {
        Text(text)
            .styleText(
                size: 12,
                weight: .regular,
                color: Color.T_1
            )
    }
}
