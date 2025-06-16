//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

#if canImport(Darwin)
import Darwin
#endif

import SwiftUI

private struct OnitPanelStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: OnitPanelState = {
        #if DEBUG
        // If this default value is fetched from a non-MainActor thread it means a view is
        // trying to read `@Environment(\.windowState)` before we have injected it. This is
        // exactly the scenario that causes the DisplayLink-thread crash.  Emit diagnostic
        // information and raise a trap so we can break in the debugger *only* when it
        // happens off the main thread (to avoid noise for normal, correct reads).

        if !Thread.isMainThread {
            // Attempt to get the current dispatch-queue label so we can filter for the
            // SwiftUI DisplayLink queue.
            let labelPtr = __dispatch_queue_get_label(nil)
            let queueLabel = String(cString: labelPtr, encoding: .utf8) ?? "<unknown>"

            // We are primarily interested in the SwiftUI.DisplayLink queue, but keeping the
            // check broad (non-main thread) is still useful. If the label matches the
            // DisplayLink queue we will raise SIGTRAP so a symbolic breakpoint will hit.
            if queueLabel.contains("com.apple.SwiftUI.DisplayLink") {
                let symbols = Thread.callStackSymbols.joined(separator: "\n")
                print("⚠️  windowState defaultValue fetched on DisplayLink queue (\(queueLabel))\n\n\(symbols)\n")
                // Raise SIGTRAP to pause execution; can be disabled by simply continuing.
                raise(SIGTRAP)
            }
        }
        #endif

        let state = OnitPanelState()
        state.defaultEnvironmentSource = "EnvironmentKey"
        return state
    }()
}

private struct OnitAppStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: AppState = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[OnitAppStateKey.self] }
        set { self[OnitAppStateKey.self] = newValue }
    }
    
    var windowState: OnitPanelState {
        get { self[OnitPanelStateKey.self] }
        set { self[OnitPanelStateKey.self] = newValue }
    }
}
