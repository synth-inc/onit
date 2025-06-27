//
//  ModelErrorView.swift
//  Onit
//
//  Created by Loyd Kim on 6/26/25.
//

import SwiftUI

struct ModelErrorView: View {
    var errorMessage: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(.warningSettings)
            
            Text(errorMessage)
                .styleText(
                    size: 13,
                    color: .orange500
                )
                .opacity(0.65)
        }
    }
}
