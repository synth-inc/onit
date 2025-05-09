//
//  SubcriptionButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import Defaults
import SwiftUI

struct SubscriptionButton: View {
    @Environment(\.openURL) var openURL
    
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    
    private let text: String
    
    init(text: String) {
        self.text = text
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: .red,
                        align: .center
                    )
            }
            
            HStack(alignment: .center, spacing: 6) {
                Image(.rocket)
                    .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 0)
                
                Text(text)
                    .styleText(size: 16, weight: .semibold)
                    .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 0)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
            .background(
              LinearGradient(
                stops: [
                  Gradient.Stop(color: Color(red: 0.3, green: 0.31, blue: 0.92), location: 0.00),
                  Gradient.Stop(color: Color(red: 0.34, green: 0.33, blue: 1), location: 0.34),
                  Gradient.Stop(color: Color(red: 0.34, green: 0.33, blue: 1), location: 0.94),
                  Gradient.Stop(color: Color(red: 0.3, green: 0.31, blue: 0.92), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
              )
            )
            .cornerRadius(16)
            .shadow(color: Color(red: 0.34, green: 0.33, blue: 1).opacity(0.35), radius: 3.5, x: 0, y: 2)
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color(red: 0.5, green: 0.52, blue: 1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.99 : 1)
            .opacity(isHovered ? 0.7 : 1)
            .addAnimation(dependency: isHovered)
            .onHover{ isHovering in isHovered = isHovering }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {_ in isPressed = true }
                    .onEnded{ _ in
                        isPressed = false
                        
                        Task {
                            if let error = await Stripe.openSubscriptionForm(openURL) {
                                errorMessage = error
                            }
                            showTwoWeekProTrialEndedAlert = false
                            hasClosedTrialEndedAlert = true
                        }
                    }
            )
        }
    }
}
