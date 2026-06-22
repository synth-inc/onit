//
//  TextButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct TextButton <Children: View>: View {
    // MARK: - Types
    
    enum ButtonType {
        case primary
        case clear
        case iosBlue
        case custom
    }
    
    struct IconConfig {
        var leftIconName: String? = nil
        var leftIconImage: ImageResource? = nil
        var leftIconNSImage: NSImage? = nil
        
        var rightIconName: String? = nil
        var rightIconImage: ImageResource? = nil
        var rightIconNSImage: NSImage? = nil
    }
    
    struct ColorConfig {
        var text: Color = Color.S_0
        var leftIcon: Color? = nil
        var rightIcon: Color? = nil
        var background: Color = Color.T_7
        var hoverBackground: Color? = nil
        var border: Color = Color.clear
    }
    
    struct SizeConfig {
        var text: CGFloat = 14
        var textWeight: Font.Weight = Font.Weight.regular
        var leftIcon: CGFloat? = nil
        var rightIcon: CGFloat? = nil
        var horizontalPadding: CGFloat = 24
        var height: CGFloat = 40
        var cornerRadius: CGFloat = 9
    }
    
    struct AlignmentConfig {
        var verticalAlignment: VerticalAlignment = VerticalAlignment.center
        var horizontalAlignment: Alignment = Alignment.center
        var gap: CGFloat = 10
    }
    
    struct TooltipConfig {
        var prompt: String? = nil
        var shortcut: Tooltip.Shortcut? = nil
    }
    
    struct StatusConfig {
        var disabled: Bool = false
        var shouldFadeOnDisabled: Bool = true
        var selected: Bool = false
        var borderDotted: Bool = false
        var fillContainer: Bool = false
    }
    
    // MARK: - Properties
    
    private let type: ButtonType
    private let text: String?
    private let fontFamily: FontFamily
    private let pointerStyle: HoverPointerStyle
    
    private let iconConfig: IconConfig
    private let colorConfig: ColorConfig
    private let sizeConfig: SizeConfig
    private let alignmentConfig: AlignmentConfig
    private let tooltipConfig: TooltipConfig
    private let statusConfig: StatusConfig
    
    @ViewBuilder private let children: () -> Children
    private let action: () -> Void
    
    // MARK: - Initializers
    
    init(
        type: ButtonType = .custom,
        text: String? = nil,
        fontFamily: FontFamily = FontFamily.system,
        pointerStyle: HoverPointerStyle = HoverPointerStyle.link,
        iconConfig: IconConfig = .init(),
        colorConfig: ColorConfig = .init(),
        sizeConfig: SizeConfig = .init(),
        alignmentConfig: AlignmentConfig = .init(),
        tooltipConfig: TooltipConfig = .init(),
        statusConfig: StatusConfig = .init(),
        
        @ViewBuilder children: @escaping () -> Children = {
            EmptyView()
        },
        
        action: @escaping () -> Void
    ) {
        self.type = type
        self.text = text
        self.fontFamily = fontFamily
        self.pointerStyle = pointerStyle
        self.iconConfig = iconConfig
        self.colorConfig = colorConfig
        self.sizeConfig = sizeConfig
        self.tooltipConfig = tooltipConfig
        self.alignmentConfig = alignmentConfig
        self.statusConfig = statusConfig
        
        self.children = children
        self.action = action
    }
    
    init(
        type: ButtonType = .custom,
        text: String? = nil,
        fontFamily: FontFamily = FontFamily.system,
        pointerStyle: HoverPointerStyle = HoverPointerStyle.link,
        iconConfig: IconConfig = .init(),
        colorConfig: ColorConfig = .init(),
        sizeConfig: SizeConfig = .init(),
        alignmentConfig: AlignmentConfig = .init(),
        tooltipConfig: TooltipConfig = .init(),
        statusConfig: StatusConfig = .init(),
        action: @escaping () -> Void
    ) where Children == EmptyView {
        self.init(
            type: type,
            text: text,
            fontFamily: fontFamily,
            pointerStyle: pointerStyle,
            iconConfig: iconConfig,
            colorConfig: colorConfig,
            sizeConfig: sizeConfig,
            alignmentConfig: alignmentConfig,
            tooltipConfig: tooltipConfig,
            statusConfig: statusConfig,
            children: { EmptyView() },
            action: action
        )
    }
    
    // MARK: - States
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    // MARK: - Private Variables
    
    private var textColor: Color {
        switch type {
        case .primary:
            return Color.black
        case .clear:
            return Color.S_0
        case .iosBlue:
            return Color.white
        case .custom:
            return colorConfig.text
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .primary:
            return Color.sky
        case .clear:
            if statusConfig.selected {
                return Color.T_9
            } else {
                return Color.clear
            }
        case .iosBlue:
            return Color.blue
        case .custom:
            return colorConfig.background
        }
    }
    
    private var backgroundHoverColor: Color {
        switch type {
        case .primary:
            return Color.sky.opacity(0.7)
        case .clear:
            return Color.T_9
        case .iosBlue:
            return Color.blue.opacity(0.7)
        case .custom:
            return
                colorConfig.hoverBackground ??
                colorConfig.background.opacity(0.7)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(
            alignment: alignmentConfig.verticalAlignment,
            spacing: alignmentConfig.gap
        ) {
            leftIconView
            textView
            children()
            rightIconView
        }
        .padding(.horizontal, sizeConfig.horizontalPadding)
        .frame(
            maxWidth: statusConfig.fillContainer ? .infinity : nil,
            alignment: alignmentConfig.horizontalAlignment
        )
        .frame(
            height: sizeConfig.height,
            alignment: .center
        )
        .onHover{ isHovering in
            isHovered = isHovering
        }
        .addButtonEffects(
            pointerStyle: pointerStyle,
            background: backgroundColor,
            hoverBackground: backgroundHoverColor,
            cornerRadius: sizeConfig.cornerRadius,
            disabled: statusConfig.disabled,
            shouldFadeOnDisabled: statusConfig.shouldFadeOnDisabled,
            allowsHitTesting: !statusConfig.disabled && !statusConfig.selected,
            isHovered: $isHovered,
            isPressed: $isPressed,
            tooltipPrompt: tooltipConfig.prompt,
            tooltipShortcut: tooltipConfig.shortcut
        ) {
            action()
        }
        .addBorder(
            cornerRadius: sizeConfig.cornerRadius,
            stroke: colorConfig.border,
            dotted: statusConfig.borderDotted
        )
    }
    
    // MARK: - Child Components
    
    @ViewBuilder
    private var textView: some View {
        if let text {
            Text(text)
                .styleText(
                    fontFamily: fontFamily,
                    size: sizeConfig.text,
                    weight: sizeConfig.textWeight,
                    color: textColor
                )
                .truncateText()
        }
    }
    
    @ViewBuilder
    private var leftIconView: some View {
        if let systemName = iconConfig.leftIconName {
            Image(systemName: systemName)
                .styleText(
                    size: sizeConfig.leftIcon ?? sizeConfig.text,
                    color: colorConfig.leftIcon ?? textColor
                )
        } else if let imageResource = iconConfig.leftIconImage {
            Image(imageResource)
                .addIconStyles(
                    foregroundColor: colorConfig.leftIcon ?? textColor,
                    iconSize: sizeConfig.leftIcon ?? sizeConfig.text + 2
                )
        } else if let nsImage = iconConfig.leftIconNSImage {
            Image(nsImage: nsImage)
                .resizable()
                .frame(
                    width: sizeConfig.leftIcon ?? sizeConfig.text + 2,
                    height: sizeConfig.leftIcon ?? sizeConfig.text + 2
                )
                .cornerRadius(4)
        }
    }
    
    @ViewBuilder
    private var rightIconView: some View {
        if let systemName = iconConfig.rightIconName {
            Image(systemName: systemName)
                .styleText(
                    size: sizeConfig.rightIcon ?? sizeConfig.text,
                    color: colorConfig.rightIcon ?? textColor
                )
        } else if let imageResource = iconConfig.rightIconImage {
            Image(imageResource)
                .addIconStyles(
                    foregroundColor: colorConfig.rightIcon ?? textColor,
                    iconSize: sizeConfig.rightIcon ?? sizeConfig.text + 2
                )
        } else if let nsImage = iconConfig.rightIconNSImage {
            Image(nsImage: nsImage)
                .resizable()
                .frame(
                    width: sizeConfig.rightIcon ?? sizeConfig.text + 2,
                    height: sizeConfig.rightIcon ?? sizeConfig.text + 2
                )
                .cornerRadius(4)
        }
    }
}
