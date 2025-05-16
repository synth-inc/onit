//
//

import Foundation
import AppKit

extension OnitPanelState {
    var isScreenMode: Bool {
        return trackedWindow == nil && trackedScreen != nil
    }
}
