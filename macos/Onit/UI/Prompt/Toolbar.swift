//
//  Toolbar.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct Toolbar: View {
    @Environment(\.model) var model

    var body: some View {
        HStack(spacing: 4) {
            esc
            resize
            Spacer()
            languageModel
            add
            history
            settings
        }
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background {
            escListener
        }
    }

    var esc: some View {
        Button {
            model.closePanel()
        } label: {
            Text("ESC")
                .appFont(.medium13)
                .padding(4)
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var escListener: some View {
        Button {
            switch model.generationState {
            case .idle:
                if model.input == nil {
                    model.closePanel()
                } else {
                    @Bindable var model = model
                    model.input = nil
                }
            default:
                model.generationState = .idle
                model.textFocusTrigger.toggle()
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.escape, modifiers: [])
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

    var languageModel: some View {
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