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
        HStack(spacing: 8) {
            Image(.warningSettings)
            
            Text(errorMessage)
                .styleText(size: 12, weight: .regular)
                .opacity(0.65)
        }
    }
}
