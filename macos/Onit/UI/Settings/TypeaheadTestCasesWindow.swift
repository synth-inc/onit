import SwiftUI
import AppKit

struct TypeaheadTestCasesWindow: View {
    var onClose: (() -> Void)?

    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Typeahead Test Cases")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button("Close") {
                    onClose?()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            
            // Content
            TypeaheadTestCasesView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1200, minHeight: 600)
        .onAppear {
            // Set up window properties
            if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                window.title = "Typeahead Test Cases"
                window.isMovableByWindowBackground = false
                window.styleMask.insert(.resizable)
                window.styleMask.insert(.miniaturizable)
                window.styleMask.insert(.closable)
            }
        }
    }
}

#Preview {
    TypeaheadTestCasesWindow()
} 