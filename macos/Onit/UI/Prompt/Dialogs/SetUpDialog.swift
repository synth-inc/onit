//
//  SetUpDialog.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct SetUpDialog<Subtitle: View>: View {
    var title: String
    @ViewBuilder var subtitle: () -> Subtitle
    var action: () -> Void
    var closeAction: () -> Void

    var borderGrad: LinearGradient {
        .init(
            stops: [
                .init(color: .border1, location: 0),
                .init(color: .border2, location: 0.46),
                .init(color: .border2, location: 0.65),
                .init(color: .border1, location: 1)
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
            button
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .background(.gray900, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderGrad, lineWidth: 1)
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
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
            }
        }
    }

    var main: some View {
        subtitle()
            .appFont(.medium13)
            .foregroundStyle(.gray100)
    }

    var button: some View {
        Button {
            action()
        } label: {
            Text("Set up →")
                .padding(8)
                .foregroundStyle(.FG)
                .background(.blue400, in: .rect(cornerRadius: 8))
                .fontWeight(.semibold)
        }
    }
}
