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

struct CheckForUpdatesView: View {
  var checkForUpdatesViewModel: CheckForUpdatesViewModel
  private let updater: SPUUpdater

  init(updater: SPUUpdater) {
    self.updater = updater
    self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
  }

  var body: some View {
    Button("Check for Updates…", action: updater.checkForUpdates)
      .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
  }
}
