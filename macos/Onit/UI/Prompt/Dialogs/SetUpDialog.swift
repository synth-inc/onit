//
//  SetUpDialog.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct SetUpDialog<Subtitle: View>: View {
    var title: String
    var showButton: Bool = true
    var buttonText: String? = nil
    var showArrow: Bool = true
    @ViewBuilder var subtitle: () -> Subtitle
    var action: () -> Void
    var closeAction: () -> Void

    var borderGrad: LinearGradient {
        .init(
            stops: [
                .init(color: .border1, location: 0),
                .init(color: .border2, location: 0.46),
                .init(color: .border2, location: 0.65),
                .init(color: .border1, location: 1),
            ],
            startPoint: .bottomTrailing,
            endPoint: .topLeading
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleView
            Spacer().frame(height: 10)
            main
            Spacer().frame(height: 11)

            if showButton {
                button
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.gray900, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderGrad, lineWidth: 1)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }

    var titleView: some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .appFont(.medium14)
                .foregroundStyle(.FG)

            Spacer()

            Button {
                closeAction()
            } label: {
                Image(.smallCross)
                    .padding(2)
            }
            .buttonStyle(HoverableButtonStyle(background: true))
        }
    }

    var main: some View {
        subtitle()
            .appFont(.medium13)
            .foregroundStyle(.gray100)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(10) // This prevents a re-draw that messes up the height of the OnitPanel in Regular mode.
    }

    var button: some View {
        Button(buttonText ?? "Set up") {
            action()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: showArrow))
    }
}
