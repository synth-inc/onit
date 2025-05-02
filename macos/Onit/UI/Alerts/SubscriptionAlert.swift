//
//  SubscriptionAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import Defaults
import SwiftUI

struct SubscriptionAlert: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    
    private let title: String
    private let close: (() -> Void)?
    private let description: String
    private let descriptionAction: (() -> Void)?
    private let caption: String?
    private let subscriptionText: String?
    private let perks: [String]?
    private let footerSupportingText: String?
    
    init(
        title: String,
        close: (() -> Void)? = nil,
        description: String,
        descriptionAction: (() -> Void)? = nil,
        caption: String? = nil,
        subscriptionText: String? = nil,
        perks: [String]? = nil,
        footerSupportingText: String? = nil
    ) {
        self.title = title
        self.close = close
        self.description = description
        self.descriptionAction = descriptionAction
        self.caption = caption
        self.subscriptionText = subscriptionText
        self.perks = perks
        self.footerSupportingText = footerSupportingText
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 16) {
                header
                
                VStack(alignment: .center, spacing: 8) {
                    if let descriptionAction = descriptionAction {
                        descriptionButton(descriptionAction)
                    } else {
                        descriptionText
                    }
                    
                    if let caption = caption {
                        Text(caption).styleText(size: 13)
                    }
                }
                
                if let subscriptionText = subscriptionText {
                    SubscriptionButton(text: subscriptionText)
                }
                
                if let perks = perks { perksList(perks) }
                
                footer
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
                    if let close = close { close() }
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
        Text(description)
            .styleText(
                size: 13,
                weight: .regular,
                color: .gray100,
                align: .center
            )
    }
    
    private func descriptionButton(_ captionAction: @escaping () -> Void) -> some View {
        Button {
            showTwoWeekProTrialEndedAlert = false
            captionAction()
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
    
    private func perksList(_ perks: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(perks, id: \.self) { perk in
                Text(perk).styleText(size: 13, weight: .regular)
            }
        }
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
    
    private func footerTextView(_ text: String) -> some View {
        Text(text).styleText(size: 11, color: .gray200)
    }
    
    private var footer: some View {
        VStack(alignment: .center, spacing: 16) {
            footerDivider
            
            VStack(alignment: .center, spacing: 4) {
                if let footerSupportingText = footerSupportingText {
                    footerTextView(footerSupportingText)
                }
                
                HStack(spacing: 4) {
                    footerTextView("Or, add your API key in")
                    
                    Button {
                        showTwoWeekProTrialEndedAlert = false
                        openModelSettings()
                    } label: {
                        Text("Settings").styleText(size: 11, color: .gray100)
                    }
                    .buttonStyle(PlainButtonStyle())
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
