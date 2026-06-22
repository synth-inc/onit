//
//  Sparkle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Combine
import Sparkle
import SwiftUI

@Observable
final class CheckForUpdatesViewModel {
    var canCheckForUpdates = false
    private var cancellables = Set<AnyCancellable>()

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
            .store(in: &cancellables)
    }
}
