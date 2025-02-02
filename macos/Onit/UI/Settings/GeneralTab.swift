import SwiftUI

struct GeneralTab: View {
    @Environment(\.model) var model
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Slider(
                            value: Binding(
                                get: { model.preferences.fontSize },
                                set: { newValue in
                                    model.updatePreferences { prefs in
                                        prefs.fontSize = newValue
                                    }
                                }
                            ),
                            in: 10...24,
                            step: 1.0
                        )
                        Text("\(Int(model.preferences.fontSize))pt")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Restore Default") {
                            model.updatePreferences { prefs in
                                prefs.fontSize = 14.0
                            }
                        }
                        .controlSize(.small)
                    }
                }
            } header: {
                Text("Appearance")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralTab()
}