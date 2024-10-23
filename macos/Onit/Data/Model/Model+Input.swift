//
//  Model+Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import AppKit

extension OnitModel {
    func setInput(_ input: Input?) {
        self.input = input
    }

    func addContext(urls: [URL]) {
        context.append(contentsOf: urls)
    }

    func removeContext(url: URL) {
        context.removeAll { $0 == url }
    }

    func focusText() {
        textFocusTrigger.toggle()
    }
}
