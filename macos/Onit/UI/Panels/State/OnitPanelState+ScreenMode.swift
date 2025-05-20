//
//

import Foundation
import AppKit

extension OnitPanelState {
    
    // TODO: KNA - Refacto: Should be removed at the end
    var isScreenMode: Bool {
        return trackedWindow == nil && trackedScreen != nil
    }
}
