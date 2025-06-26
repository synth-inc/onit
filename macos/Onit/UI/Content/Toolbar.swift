//
//  Toolbar.swift
//  Onit
//
//  Created by Loyd Kim on 6/24/25.
//

import SwiftUI

struct Toolbar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                ToolbarLeft()
                Spacer()
                ToolbarRight()
            }
            .padding(.top, 1)
            .padding(.trailing, 8)
            .padding(.leading, 12)
            .frame(height: 31)
            
            PromptDivider()
        }
    }
}
