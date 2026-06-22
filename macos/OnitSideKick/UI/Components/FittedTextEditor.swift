//
//  FittedTextEditor.swift
//  Onit
//
//  Created by Loyd Kim on 2/13/26.
//

import SwiftUI

struct FittedTextEditor: View {
    // MARK: - Types
    
    struct SizeConfigs {
        var paddingVertical: CGFloat = 10
        var paddingHorizontal: CGFloat = 12
    }
    
    struct ColorConfigs {
        var unfocusedBackground: Color = Color.clear
        var focusedBackground: Color = Color.clear
        var hoverBackground: Color = Color.clear
        var border: Color = Color.clear
        var cornerRadius: CGFloat = 9
    }
    
    struct TextConfigs {
        var size: CGFloat = 14
        var weight: Font.Weight = Font.Weight.regular
        var placeholderTextColor: Color = Color.S_1
        var textEditorTextColor: Color = Color.S_0
    }
    
    // MARK: - Properties
    
    @Binding var text: String
    var placeholderText: String? = nil
    var sizeConfigs: SizeConfigs = .init()
    var colorConfigs: ColorConfigs = .init()
    var textConfigs: TextConfigs = .init()
    var shouldFocusOnAppear: Bool = false
    
    // MARK: - States
    
    @FocusState private var isFocused: Bool
    
    @State private var textEditorHeight: CGFloat = 0
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    // MARK: - Private Variables
    
    /// Accounting for `NSTextView`'s `lineFragmentPadding`, which applies an internal 5px padding to `TextEditor`.
    private let textEditorLineFragmentPadding: CGFloat = 5
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .leading) {
            textEditorSizingGuide
            placeholderView
            textEditorView
        }
    }

    // MARK: - Child Components

    /// Invisible `Text` view that measures the required height necessary to display all `text` content in `textEditorView`.
    private var textEditorSizingGuide: some View {
        Text(text.isEmpty ? " " : text)
            .padding(.vertical, sizeConfigs.paddingVertical)
            .padding(.horizontal, sizeConfigs.paddingHorizontal + textEditorLineFragmentPadding)
            .styleText(
                size: textConfigs.size,
                weight: textConfigs.weight,
                color: textConfigs.textEditorTextColor
            )
            .onHeightChanged {
                textEditorHeight = $0
            }
            .opacity(0)
            .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if let placeholderText = self.placeholderText,
           text.isEmpty
        {
            Text(placeholderText)
                .padding(.vertical, sizeConfigs.paddingVertical)
                .padding(.horizontal, sizeConfigs.paddingHorizontal + textEditorLineFragmentPadding)
                .styleText(
                    size: textConfigs.size,
                    weight: textConfigs.weight,
                    color: textConfigs.placeholderTextColor
                )
                .allowsHitTesting(false)
        }
    }
    
    private var textEditorView: some View {
        TextEditor(text: $text)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .padding(.vertical, sizeConfigs.paddingVertical)
            .padding(.horizontal, sizeConfigs.paddingHorizontal)
            .frame(height: textEditorHeight)
            .background(
                isFocused ?
                    colorConfigs.focusedBackground :
                    colorConfigs.unfocusedBackground
            )
            .styleText(
                size: textConfigs.size,
                weight: textConfigs.weight,
                color: textConfigs.textEditorTextColor
            )
            .addBorder(
                cornerRadius: colorConfigs.cornerRadius,
                stroke: colorConfigs.border
            )
            .addButtonEffects(
                background:
                    isFocused ?
                        colorConfigs.focusedBackground :
                        colorConfigs.unfocusedBackground,
                hoverBackground: colorConfigs.hoverBackground,
                cornerRadius: colorConfigs.cornerRadius,
                isHovered: isFocused ? .constant(false) : $isHovered,
                isPressed: isFocused ? .constant(false) : $isPressed
            )
            .addAnimation(dependency: isFocused)
            .focused($isFocused)
            .onAppear {
                isFocused = shouldFocusOnAppear
            }
    }
}
