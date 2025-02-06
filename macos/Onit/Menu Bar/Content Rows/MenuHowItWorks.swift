//
//  MenuHowItWorks.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuHowItWorks: View {
    var body: some View {
        MenuBarRow {

        } leading: {
            Text("How it Works")
                .padding(.leading, 10)
        } trailing: {
            Color.clear
                .frame(width: 1)
        }
    }
}

#Preview {
    MenuHowItWorks()
}
