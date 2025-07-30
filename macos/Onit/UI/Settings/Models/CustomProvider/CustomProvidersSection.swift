import Defaults
import SwiftData
import SwiftUI

struct CustomProvidersSection: View {
    @Default(.availableCustomProviders) private var availableCustomProvider

    @State private var showForm = false
    @State private var isSubmitted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            title
            caption

            ForEach($availableCustomProvider) { provider in
                CustomProviderRow(provider: provider)
            }
        }
    }
    var title: some View {
        HStack {
            Text("Other providers / private models")
                .font(.system(size: 13))

            Spacer()

            Button {
                showForm = true
            } label: {
                Text("Add new")
            }
            .foregroundStyle(Color.S_0)
            .buttonStyle(.borderedProminent)
            .frame(height: 22)
            .fontWeight(.regular)
        }
        .sheet(isPresented: $showForm) {
            CustomProviderFormView(isSubmitted: $isSubmitted)
        }
        .onChange(of: isSubmitted, initial: false) { old, new in
            if new {
                isSubmitted = false
            }
        }
    }

    var caption: some View {
        Text("Manually add remote models from other providers.")
            .foregroundStyle(.foreground.opacity(0.65))
            .fontWeight(.regular)
            .font(.system(size: 12))
    }

}

#Preview {
    CustomProvidersSection()
}
