//
//  Toolbar.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct Toolbar: View {
    var body: some View {
        HStack(spacing: 4) {
            esc
            resize
            Spacer()
            model
            add
            history
            settings
        }
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
    }

    var esc: some View {
        Button {
            print("ESC")
            if let window = NSApplication.shared.windows.first {
                window.close()
            } else {
                print("Error closing window")
            }
        } label: {
            Text("ESC")
                .appFont(.medium13)
                .padding(4)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var resize: some View {
        Button {

        } label: {
            Image(.resize)
                .renderingMode(.template)
                .padding(3)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var model: some View {
        Button {

        } label: {
            Image(.stars)
                .renderingMode(.template)
                .padding(2)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var add: some View {
        Button {

        } label: {
            Image(.circlePlus)
                .renderingMode(.template)
                .padding(2)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var history: some View {
        Button {

        } label: {
            Image(.history)
                .renderingMode(.template)
                .padding(2)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var settings: some View {
        Button {

        } label: {
            Image(.settingsCog)
                .renderingMode(.template)
                .padding(2)
        }
        .buttonStyle(HoverableButtonStyle())
    }
}

#Preview {
    Toolbar()
}
