//
//  FeatureDisableWindow.swift
//  Onit
//
//  Created by Loyd Kim on 10/20/25.
//

import SwiftUI

final class FeatureDisableWindow: CenteredWindow<FeatureDisableWindowView> {
    init(
        foregroundWindow: TrackedWindow?,
        disableType: FeatureDisableWindowDisableType
    ) {
        super.init(
            rootView: FeatureDisableWindowView(
                foregroundWindow: foregroundWindow,
                disableType: disableType
            ),
            hideTitleBar: true,
            canDrag: false
        )
    }
}
