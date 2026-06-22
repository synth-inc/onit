//
//  PopoverButtonsView.swift
//  Onit
//
//  Created by Loyd Kim on 5/13/26.
//

import SwiftUI

struct PopoverButtonsView: View {
    // MARK: - Types
    
    typealias ColorConfig = TextButton<EmptyView>.ColorConfig
    typealias IconConfig = TextButton<EmptyView>.IconConfig
    typealias SizeConfig = TextButton<EmptyView>.SizeConfig
    typealias StatusConfig = TextButton<EmptyView>.StatusConfig
    
    @MainActor
    struct ButtonItem: Identifiable {
        let id = UUID()
        let text: String
        var colorConfig: ColorConfig = PopoverButtonsView.buttonColorConfig()
        var iconConfig: IconConfig = .init()
        var sizeConfig: SizeConfig = PopoverButtonsView.buttonSizeConfig()
        var statusConfig: StatusConfig = PopoverButtonsView.buttonStatusConfig()
        let action: () -> Void
    }
    
    // MARK: - Properties
    
    let items: [ButtonItem]
    var minWidth: CGFloat = 230
    
    // MARK: - Static Functions
    
    static func buttonColorConfig(
        text: Color = Color.S_0,
        background: Color = Color.clear,
        hoverBackground: Color = Color.T_9
    ) -> ColorConfig {
        return .init(
            text: text,
            background: background,
            hoverBackground: hoverBackground
        )
    }
    
    static func buttonSizeConfig(leftIcon: CGFloat = 16) -> SizeConfig {
        return .init(
            textWeight: .regular,
            leftIcon: leftIcon,
            horizontalPadding: 8,
            height: 36
        )
    }
    
    static func buttonStatusConfig(
        disabled: Bool = false,
        selected: Bool = false
    ) -> StatusConfig {
        return .init(
            disabled: disabled,
            selected: selected,
            fillContainer: true
        )
    }

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                TextButton(
                    text: item.text,
                    iconConfig: item.statusConfig.selected ? .init(leftIconName: "checkmark") : item.iconConfig,
                    colorConfig: item.colorConfig,
                    sizeConfig: item.statusConfig.selected ? Self.buttonSizeConfig(leftIcon: 12) : item.sizeConfig,
                    alignmentConfig: .init(
                        horizontalAlignment: .leading,
                        gap: 8
                    ),
                    statusConfig: item.statusConfig
                ) {
                    item.action()
                }
            }
        }
        .padding(8)
        .frame(minWidth: minWidth, alignment: .leading)
    }
}
