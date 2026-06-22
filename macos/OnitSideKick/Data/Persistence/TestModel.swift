//
//  TestModel.swift
//  Onit
//
//  Created by Timothy Lenardo on 1/15/25.
//

import Foundation
import SwiftData

@Model
class TestModel {
    var text: String
    var input: Input?
    var contextList: [Context] = []
    var responses: [Response] = []

    var fetchingError: FetchingError? = nil

    // This crashes
    //    var generationState: GenerationState? = GenerationState.idle

    init(text: String, input: Input? = nil, contextList: [Context] = []) {
        self.text = text
        self.input = input
    }
}
