//
//  SetUpDialog.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct SetUpDialog<Subtitle: View>: View {
    var title: String
    var icon: String? = nil
    var titleColor: Color? = nil
    var showButton: Bool = true
    var buttonText: String? = nil
    var buttonStyle: SetUpButtonVariant = .default
    var showArrow: Bool = true
    @ViewBuilder var subtitle: () -> Subtitle
    var action: (() -> Void)? = nil
    var closeAction: (() -> Void)? = nil

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

            if showButton && action != nil {
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
            if let icon = icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(0)
                    .foregroundStyle(titleColor ?? .FG)
            }
            
            Text(title)
                .fontWeight(.semibold)
                .appFont(.medium14)
                .foregroundStyle(titleColor ?? .FG)

            Spacer()

            if let closeAction = closeAction {
                Button {
                    closeAction()
                } label: {
                    Image(.smallCross)
                        .padding(2)
                }
                .buttonStyle(HoverableButtonStyle(background: true))
            }
        }
    }

    var main: some View {
        subtitle()
            .appFont(.medium13)
            .foregroundStyle(.gray100)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(10)
            .padding(.leading, icon != nil ? 28 : 0)
    }

    var button: some View {
        Button(buttonText ?? "Set up") {
            action?()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: showArrow, variant: buttonStyle))
        .padding(.leading, icon != nil ? 28 : 0)
    }
}
