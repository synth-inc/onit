//
//  CustomTextField.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftUI

struct CustomTextField: View {
    
    struct Config {
        var clear: Bool = false
        var leftIcon: ImageResource? = nil
    }

    var title: String
    @Binding var text: String
    
    private let config: Config
    private let imageSize: CGFloat = 16
    
    private var leadingPadding: CGFloat {
        if let _ = config.leftIcon {
            return imageSize + 8
        } else {
            return 0
        }
    }
    
    private var trailingPadding: CGFloat {
        if config.clear && !text.isEmpty {
            return imageSize + 8
        } else {
            return 0
        }
    }

    init(_ title: String, text: Binding<String>, config: Config = Config()) {
        self.title = title
        _text = text
        self.config = config
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ZStack(alignment: .trailing) {
                TextField(title, text: $text)
                    .textFieldStyle(.plain)
                    .padding(EdgeInsets(top: 8,
                                        leading: leadingPadding,
                                        bottom: 8,
                                        trailing: trailingPadding))
                
                if config.clear && !text.isEmpty {
                    Image(.smallCross)
                        .resizable()
                        .frame(width: imageSize, height: imageSize)
                        .padding(.trailing, 4)
                        .onTapGesture {
                            text = ""
                        }
                }
            }
            
            if let leftIcon = config.leftIcon {
                Image(leftIcon)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                    .padding(.leading, 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(lineWidth: 1.0)
                .fill(.gray500)
        )
    }
}

#Preview {
    CustomTextField("Some title", text: .constant("fea"))
}
