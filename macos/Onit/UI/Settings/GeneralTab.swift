import SwiftUI
import Defaults
import ServiceManagement

struct GeneralTab: View {
    @Default(.fontSize) var fontSize
    @Default(.panelPosition) var panelPosition
    
    @State var isLaunchAtStartupEnabled: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            launchOnStartupSection
            
            appearanceSection
        }
        .formStyle(.grouped)
        .padding()
    }
    
    var launchOnStartupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Run onit when my computer starts")
                        .font(.system(size: 13))
                    
                    Spacer()
                    
                    Toggle("", isOn: $isLaunchAtStartupEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .onChange(of: isLaunchAtStartupEnabled, initial: false) { old, new in
                toggleLaunchAtStartup()
            }
        } header: {
            HStack {
                Image(systemName: "power")
                Text("Auto start")
            }
        }
    }
    
    var appearanceSection: some View {
        Section {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Slider(
                            value: $fontSize,
                            in: 10...24,
                            step: 1.0
                        )
                        Text("\(Int(fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Restore Default") {
                            _fontSize.reset()
                        }
                        .controlSize(.small)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Panel Position")
                        .font(.system(size: 13))
                    
                    HStack(spacing: 8) {
                        ForEach(PanelPosition.allCases, id: \.self) { position in
                            Button {
                                panelPosition = position
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: position.systemImage)
                                        .font(.system(size: 16))
                                    Text(position.rawValue)
                                        .font(.system(size: 11))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(panelPosition == position ? Color(.blue300) : Color(.gray700))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Image(systemName: "paintbrush")
                Text("Appearance")
            }
        }
    }
    
    private func toggleLaunchAtStartup() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Error : \(error)")
        }
    }
}

#Preview {
    GeneralTab()
}
