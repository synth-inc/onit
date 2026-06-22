//
//  Toolbar.swift
//  Onit
//
//  Created by Loyd Kim on 6/24/25.
//

import SwiftUI

struct Toolbar: View {
    var mode: InferenceMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                ToolbarLeft()
                Spacer()
                ToolbarRight(mode: mode)
            }
            .padding(.trailing, 8)
            .padding(.leading, 12)
            .frame(height: 40)
            
            DividerHorizontal()
        }
    }
}
