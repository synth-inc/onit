//
//  TextContextHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 6/3/25.
//

struct TextContextHelpers {
    static func checkContextTextAlreadyAdded(
        contextList: [Context],
        text: String
    ) -> Bool {
        return contextList.contains { context in
            if case .text(let textContext, _) = context {
                return textContext.selectedText == text
            }
            return false
        }
    }

    static func getNotpinnedTextContext(contextList: [Context]) -> Context? {
        return contextList.first(where: { context in
            if case .text(_, let isPinned) = context, !isPinned { return true }
            else { return false }
        })
    }
}
