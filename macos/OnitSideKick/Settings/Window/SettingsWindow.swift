//
//  SettingsWindow.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import SwiftUI

final class SettingsWindow: CenteredWindow<SettingsWindowView> {
    init() {
        super.init(
            rootView: SettingsWindowView(),
            windowSize: (
                width: 750,
                height: 640
            )
        )
    }
}
