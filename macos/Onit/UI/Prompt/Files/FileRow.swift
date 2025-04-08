//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct FileRow: View {
    var contextList: [Context]

    var body: some View {
        HStack(spacing: 6) {
            PaperclipButton()
            
            if !contextList.isEmpty {
                ContextList(contextList: contextList)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#if DEBUG
    #Preview {
        FileRow(contextList: [])
    }
#endif
