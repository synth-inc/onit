//
//  FeatureFlagManagerLogic.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import Foundation

/**
 * Logic used to manage the feature flag system
 */
protocol FeatureFlagManagerLogic {
    
    /** Initialize the system */
    func configure()
    
    /** Reload / Fetch configuration */
    func reload()
    
    /**
     * Check if accessibility feature is enabled
     * - returns: True if accessibility is enabled, false otherwise
     */
    func isAccessibilityEnabled() -> Bool
}
