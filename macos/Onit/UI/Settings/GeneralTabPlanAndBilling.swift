//
//  GeneralTabPlanAndBilling.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import SwiftUI

struct GeneralTabPlanAndBilling: View {
    var body: some View {
        SettingsSection(
            iconText: "􀋃",
            title: "Plan and billing"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                Button {
                    print("Foo")
                } label: {
                    HStack(alignment: .center, spacing: 3) {
                        Text("🚀").styleText(size: 12, weight: .regular)
                        Text("Upgrade to PRO").styleText(size: 13, weight: .regular)
                    }
                }
                .buttonStyle(DefaultButtonStyle())
                .background(.blue)
                .cornerRadius(5)
                
                VStack(alignment: .leading, spacing: 9) {
                    Text("⭐️ 1000 generations").styleText(size: 13)
                    Text("⭐️ Access to all features").styleText(size: 13)
                    Text("⭐️ Priority support").styleText(size: 13)
                }
            }
        }
    }
}
