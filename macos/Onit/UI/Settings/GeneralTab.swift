import SwiftUI

struct GeneralTab: View {
    @Environment(\.model) var model
    
    var body: some View {
        Form {
            Section {
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