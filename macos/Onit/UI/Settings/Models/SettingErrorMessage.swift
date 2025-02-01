import SwiftUI

struct SettingErrorMessage: View {
    let message: String?
    
    var body: some View {
        if let message = message {
            Text(message)
                .foregroundStyle(.red)
                .font(.system(size: 10))
                .padding(.leading, 4)
        }
    }
}