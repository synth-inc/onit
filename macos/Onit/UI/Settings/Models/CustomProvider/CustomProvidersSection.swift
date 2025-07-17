import Defaults
import SwiftData
import SwiftUI

struct CustomProvidersSection: View {
    @Default(.availableCustomProviders) private var availableCustomProvider

    @State private var showForm = false
    @State private var isSubmitted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    title
                    caption
                }
                
                Spacer()
                
                addNewButton
            }
            .sheet(isPresented: $showForm) {
                CustomProviderFormView(isSubmitted: $isSubmitted)
            }
            .onChange(of: isSubmitted, initial: false) { old, new in
                if new {
                    isSubmitted = false
                }
            }
            

            ForEach($availableCustomProvider) { provider in
                CustomProviderRow(provider: provider)
            }
        }
    }
    
    private var title: some View {
        Text("Other providers / private models")
            .styleText(size: 13)
    }

    private var caption: some View {
        Text("Manually add remote models from other providers.")
            .styleText(
                size: 12,
                weight: .regular,
                color: Color.primary.opacity(0.65)
            )
    }
    
    private var addNewButton: some View {
        SimpleButton(text: "Add new") {
            showForm = true
        }
    }
}

#Preview {
    CustomProvidersSection()
}
