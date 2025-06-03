//
//  TextContextHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 6/3/25.
//

func checkContextTextAlreadyAdded(contextList: [Context], text: String) -> Bool {
    return contextList.contains { context in
        if case .text(let textContext) = context {
            return textContext.selectedText == text
        }
        return false
    }
}
