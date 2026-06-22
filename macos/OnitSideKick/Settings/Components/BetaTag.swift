//
//  BetaTag.swift
//  Onit
//

import SwiftUI

struct BetaTag: View {
    var text: String? = nil
    
    var body: some View {
        Text(text ?? String.localized("Beta", table: "App"))
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.sky)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
