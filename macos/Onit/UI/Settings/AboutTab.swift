import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("AppIcon")
                .resizable()
                .frame(width: 128, height: 128)
            
            VStack(spacing: 4) {
                Text("Onit")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button("Visit Website") {
                    if let url = URL(string: "https://www.getonit.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Contact Us") {
                    if let url = URL(string: "mailto:contact@getonit.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Send Feedback") {
                    if let url = URL(string: "mailto:support@getonit.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    AboutTab()
}