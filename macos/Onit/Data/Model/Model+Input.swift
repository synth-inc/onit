//
//  Model+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Foundation

extension OnitModel {
    func setInput(_ input: Input?) {
        self.input = input
    }

    func focusText() {
        textFocusTrigger.toggle()
    }
}
