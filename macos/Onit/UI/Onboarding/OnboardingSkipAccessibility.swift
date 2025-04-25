//
//  OnboardingSkipAccessibility.swift
//  Onit
//
//  Created by Loyd Kim on 4/24/25.
//

import Defaults
import SwiftUI

struct OnboardingSkipAccessibility: View {
    private var showSkipConfirmation: Binding<Bool>
    
    init(showSkipConfirmation: Binding<Bool>) {
        self.showSkipConfirmation = showSkipConfirmation
    }
    
    @State private var isHoveringClose = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            header
            
            Text("Onit has been designed to work side-by-side with accessibility permission and relies on it for a lot of its features.")
                .styleText(size: 13, color: .gray100)
            
            Button {
                Defaults[.showOnboarding] = false
            } label: {
                Text("Yes, continue →")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.gray900)
        .addBorder()
    }
}

// MARK: - Child Components

extension OnboardingSkipAccessibility {
    private var header: some View {
        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {
                Text("Continue with\na limited experience?")
                    .styleText(size: 16, weight: .bold)
                
                Spacer()
                
                Button {
                    showSkipConfirmation.wrappedValue = false
                } label: {
                    Image(.smallCross).addIconStyles(
                        foregroundColor: isHoveringClose ? .white : .gray200
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, -6)
                .padding(.trailing, -6)
                .addAnimation(dependency: isHoveringClose)
                .onHover { isHovering in isHoveringClose = isHovering}
            }
        }
    }
}
