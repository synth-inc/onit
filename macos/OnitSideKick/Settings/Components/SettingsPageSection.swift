//
//  SettingsPageSection.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import SwiftUI

struct SettingsPageSection<Children: View>: View {
    // MARK: Types
    
    struct TextConfigs {
        var text: String
        var paddingHorizontal: CGFloat = 0
    }

    struct SizeConfigs {
        var cornerRadius: CGFloat = 20
        var padding: CGFloat = 16
        var groupSpacing: CGFloat = 12
    }

    struct ColorConfigs {
        var background: Color = Color.S_6
        var border: Color = Color.T_9
    }
    
    struct StatusConfigs {
        var isGroup: Bool = false
        var isObscured: Bool = false
        var borderDotted: Bool = false
    }
    
    // MARK: - Properties
    
    var title: TextConfigs? = nil
    var subtitle: TextConfigs? = nil
    var size: SizeConfigs = .init()
    var color: ColorConfigs = .init()
    var status: StatusConfigs = .init()
    @ViewBuilder let children: () -> Children
    
    // MARK: - Body
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            if title != nil || subtitle != nil {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    if let title = self.title {
                        Text(title.text)
                            .padding(.horizontal, title.paddingHorizontal)
                            .styleText(
                                weight: .regular,
                                color: Color.T_2
                            )
                    }
                    
                    if let subtitle = self.subtitle {
                        Text(subtitle.text)
                            .padding(.horizontal, subtitle.paddingHorizontal)
                            .styleText(
                                size: 11,
                                weight: .regular,
                                color: Color.T_2
                            )
                    }
                }
            }
            
            VStack(
                alignment: .leading,
                spacing: size.groupSpacing
            ) {
                children()
            }
            .padding(size.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.background)
            .addBorder(
                cornerRadius:size.cornerRadius,
                stroke:color.border,
                dotted: status.borderDotted
            )
            .overlay {
                if status.isObscured {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(.regularMaterial)
                        .opacity(0.9)
                }
            }
            .allowsHitTesting(!status.isObscured)
        }
    }
}
