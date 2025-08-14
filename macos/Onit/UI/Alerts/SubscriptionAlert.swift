//
//  SubscriptionAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct SubscriptionAlert<Child: View>: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    private let title: String
    private let close: (() -> Void)?
    private let description: String
    private let descriptionLoading: Bool
    private let descriptionAction: (() -> Void)?
    private let descriptionActionLoading: Bool
    private let caption: String?
    private let spacingBetweenSections: CGFloat
    private let showApiCta: Bool
    private let subscriptionText: String?
    private let subscriptionAction: (() -> Void)?
    private let showSubscriptionPerks: Bool
    private let footerSupportingText: String?
    private let errorMessage: Binding<String>?
    @ViewBuilder private let child: () -> Child
    
    init(
        title: String,
        close: (() -> Void)? = nil,
        description: String,
        descriptionLoading: Bool = false,
        descriptionAction: (() -> Void)? = nil,
        descriptionActionLoading: Bool = false,
        caption: String? = nil,
        spacingBetweenSections: CGFloat = 16,
        showApiCta: Bool = true,
        subscriptionText: String? = nil,
        subscriptionAction: (() -> Void)? = nil,
        showSubscriptionPerks: Bool = false,
        footerSupportingText: String? = nil,
        errorMessage: Binding<String>? = nil,
        @ViewBuilder child: @escaping () -> Child = { EmptyView() }
    ) {
        self.title = title
        self.close = close
        self.description = description
        self.descriptionLoading = descriptionLoading
        self.descriptionAction = descriptionAction
        self.descriptionActionLoading = descriptionActionLoading
        self.caption = caption
        self.spacingBetweenSections = spacingBetweenSections
        self.showApiCta = showApiCta
        self.subscriptionText = subscriptionText
        self.subscriptionAction = subscriptionAction
        self.showSubscriptionPerks = showSubscriptionPerks
        self.footerSupportingText = footerSupportingText
        self.errorMessage = errorMessage
        self.child = child
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: spacingBetweenSections) {
                if let errorMessage = errorMessage,
                    !errorMessage.wrappedValue.isEmpty
                {
                    Text(errorMessage.wrappedValue)
                        .styleText(
                            size: 13,
                            weight: .regular,
                            color: .red
                        )
                }
                
                header
                
                VStack(alignment: .center, spacing: 8) {
                    if descriptionActionLoading {
                        Shimmer(width: 220, height: 16)
                    } else if let descriptionAction = descriptionAction {
                        descriptionButton(descriptionAction)
                            .opacity(descriptionActionLoading ? 0.5 : 1)
                            .allowsHitTesting(!descriptionActionLoading)
                    } else {
                        descriptionText
                    }
                    
                    if let caption = caption {
                        captionText(caption)
                    }
                }
                
                if let subscriptionText = subscriptionText {
                    SubscriptionButton(text: subscriptionText, action: subscriptionAction)
                }
                
                if showSubscriptionPerks {
                    SubscriptionFeatures(centerErrorText: true)
                }
                
                footer
                
                child()
            }
            .padding(16)
            .background(.gray900)
            .addBorder()
            .padding(22)
            .transition(.opacity)
        }
        .frame(maxHeight: .infinity)
        .background(
            Color.black
                .opacity(0.8)
                .onTapGesture {
                    close?()
                }
        )
    }
}

// MARK: - Child Components

extension SubscriptionAlert {
    private func closeButton(_ close: @escaping () -> Void) -> some View {
        Button {
            close()
        } label: {
            Image(.smallCross)
                .addIconStyles(foregroundColor: .gray200, iconSize: 18)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: 6, y: -6)
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            if let close = close { closeButton(close).opacity(0).allowsHitTesting(false) }
            Spacer()
            
            Text(title).styleText(size: 16, weight: .semibold)
            
            Spacer()
            if let close = close { closeButton(close) }
        }
    }
    
    private var descriptionText: some View {
        captionText(description)
    }
    
    private func descriptionButton(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(description)
                .styleText(
                    size: 13,
                    weight: .regular,
                    align: .center
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var footerDivider: some View {
        Rectangle()
          .foregroundColor(.clear)
          .frame(height: 1)
          .background(
            LinearGradient(
              stops: [
                Gradient.Stop(color: Color(red: 0.09, green: 0.09, blue: 0.1), location: 0.00),
                Gradient.Stop(color: Color(red: 0.2, green: 0.21, blue: 0.23), location: 0.31),
                Gradient.Stop(color: Color(red: 0.2, green: 0.21, blue: 0.23), location: 0.73),
                Gradient.Stop(color: Color(red: 0.09, green: 0.09, blue: 0.1), location: 1.00),
              ],
              startPoint: UnitPoint(x: 0, y: 0.5),
              endPoint: UnitPoint(x: 1, y: 0.5)
            )
          )
    }
    
    private func captionText(_ text: String) -> some View {
        Text(text).styleText(size: 13, weight: .regular, color: .gray100, align: .center)
    }
    
    private var footer: some View {
        VStack(alignment: .center, spacing: spacingBetweenSections) {
            footerDivider
            
            VStack(alignment: .center, spacing: 4) {
                if let footerSupportingText = footerSupportingText {
                    captionText(footerSupportingText)
                }
                
                if showApiCta {
                    HStack(spacing: 4) {
                        captionText("Or, add your API key in")
                        
                        Button {
                            openModelSettings()
                        } label: {
                            Text("Settings").styleText(size: 13, weight: .regular, color: .primary, align: .center)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: -  Private Functions

extension SubscriptionAlert {
    private func openModelSettings() {
        NSApp.activate()
        
        if NSApp.isActive {
            appState.setSettingsTab(tab: .models)
            openSettings()
        }
    }
}
