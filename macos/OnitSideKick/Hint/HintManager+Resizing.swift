//
//  HintManager+Resizing.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions: Hint Resizing
 */

import AppKit

extension HintManager {
    // MARK: - Public Functions: Hint Resizing

    func updateHintSize() {
        if let fittingSize = hintWindow.contentView?.fittingSize {
            currentHintSize = fittingSize
        }
    }
}
