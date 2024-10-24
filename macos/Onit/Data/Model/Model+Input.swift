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
        context += urls.map(Context.init)
    }

    func removeContext(context: Context) {
        self.context.removeAll { $0 == context }
    }

    func focusText() {
        textFocusTrigger.toggle()
    }
}
