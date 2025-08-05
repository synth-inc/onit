//
//  GeneralTabAccountAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/13/25.
//

import SwiftUI

struct GeneralTabAccountAlert: View {
    let show: Binding<Bool>
    let logout: () -> Void
    
    @State private var deleteText: String = ""
    @State private var accountDeleteError: String = ""
    
    @State private var isHoveredCancel: Bool = false
    @State private var isPressedCancel: Bool = false
    @State private var isHoveredDelete: Bool = false
    @State private var isPressedDelete: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 10) {
                title
                caption
            }
            
            TextField("DELETE", text: $deleteText)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(height: 22)
                .padding(.horizontal, 7)
                .background(Color.T_9)
                .cornerRadius(5)
                .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.3), radius: 1.25, x: 0, y: 0.5)
            
            HStack(spacing: 8) {
                cancelButton
                deleteButton
            }
        }
        .frame(width: 260)
        .padding(16)
        .background(GlassBackground())
        .cornerRadius(10)
    }
}

// MARK: - Child Components

extension GeneralTabAccountAlert {
    private var title: some View {
        Text("Are you sure you want to delete your account?")
            .styleText(size: 13, weight: .semibold, align: .center)
            .padding(.top, 4)
    }
    
    private var caption: some View {
        Text("Confirm by writing \"DELETE\" below")
            .styleText(size: 11, weight: .regular, align: .center)
    }
    
    private func button(
        text: String,
        disabled: Bool = false,
        allowsHitTesting: Bool = true,
        isCritical: Bool = false,
        isHovered: Binding<Bool>,
        isPressed: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .center) {
            Text(text)
                .styleText(size: 13, weight: .regular, color: isCritical ? Color.red500 : Color.S_0)
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .cornerRadius(5)
        .addButtonEffects(
            background: isCritical ? Color.redDisabled : Color.T_9,
            hoverBackground: isCritical ? Color.redDisabledHover : Color.T_8,
            cornerRadius: 5,
            disabled: disabled,
            allowsHitTesting: allowsHitTesting,
            isHovered: isHovered,
            isPressed: isPressed,
            action: action
        )
    }
    
    private var cancelButton: some View {
        button(
            text: "Cancel",
            isHovered: $isHoveredCancel,
            isPressed: $isPressedCancel
        ) {
            AnalyticsManager.AccountEvents.deleteConfirmationCancelPressed()
            show.wrappedValue.toggle()
        }
    }
    
    private var deleteButton: some View {
        button(
            text: "Delete",
            disabled: deleteText != "DELETE",
            allowsHitTesting: deleteText == "DELETE",
            isCritical: true,
            isHovered: $isHoveredDelete,
            isPressed: $isPressedDelete
        ) {
            deleteAccount()
        }
    }
}

// MARK: - Private Functions

extension GeneralTabAccountAlert {
    @MainActor
    private func deleteAccount() {
        AnalyticsManager.AccountEvents.deleteConfirmationDeletePressed()
        
        accountDeleteError = ""
        let client = FetchingClient()
        
        Task {
            do {
                try await client.deleteAccount()
                logout()
            } catch {
                accountDeleteError = error.localizedDescription
            }
        }
    }
}
