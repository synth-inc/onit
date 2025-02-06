import SwiftUI
import Defaults

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("Onit")
                .resizable()
                .frame(width: 56, height: 56)
            
            VStack(spacing: 4) {
                Text("Onit")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                    .foregroundColor(.secondary)
                
                if FeatureFlagManager.shared.showLegacyClientCantUpdateDialog {
                    Text("This version can't be updated automatically.\nTo get the latest, please delete this version and download a new version from our website.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            
            VStack(spacing: 12) {
                if FeatureFlagManager.shared.showLegacyClientCantUpdateDialog {
                    Button("Download New Version") {
                        if let url = URL(string: "https://www.getonit.ai") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.borderedProminent)
                    .frame(height: 22)
                    .fontWeight(.regular)
                }
                
                HStack(spacing: 12) {
                    if !FeatureFlagManager.shared.showLegacyClientCantUpdateDialog {
                        Button("Visit Website") {
                            if let url = URL(string: "https://www.getonit.ai") {
                                NSWorkspace.shared.open(url)
                            }
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    AboutTab()
}
