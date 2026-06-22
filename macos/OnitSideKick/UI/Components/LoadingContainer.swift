//
//  LoadingContainer.swift
//  Onit
//
//  Created by Loyd Kim on 3/30/26.
//

import SwiftUI

struct LoadingContainer<
    LoaderView: View,
    LoadedView: View
>: View {
    // MARK: - Properties

    let isLoading: Bool
    var minimumLoadingDuration: TimeInterval = 0.3
    @ViewBuilder let loaderView: () -> LoaderView
    @ViewBuilder let loadedView: () -> LoadedView

    // MARK: - States

    @State private var shouldShowLoader = false
    @State private var loaderStartTime: Date? = nil
    @State private var loadingTask: Task<Void, Never>? = nil

    // MARK: - Body

    var body: some View {
        Group {
            if shouldShowLoader {
                loaderView()
            } else {
                loadedView()
            }
        }
        .onAppear {
            showLoaderIfNeeded()
        }
        .onDisappear {
            resetStates()
        }
        .onChange(of: isLoading) { _, loading in
            loadingTask?.cancel()

            if loading {
                showLoader()
            } else {
                scheduleTransitionToLoadedView()
            }
        }
    }

    // MARK: - Private Functions
    
    private func showLoaderIfNeeded() {
        if isLoading {
            showLoader()
        }
    }
    
    private func showLoader() {
        shouldShowLoader = true
        loaderStartTime = Date()
    }
    
    private func resetStates() {
        loadingTask?.cancel()
        loadingTask = nil
        loaderStartTime = nil
        shouldShowLoader = false
    }

    private func scheduleTransitionToLoadedView() {
        guard shouldShowLoader,
              let loaderStartTime
        else {
            shouldShowLoader = false
            return
        }

        let elapsedLoadingTime = Date().timeIntervalSince(loaderStartTime)
        let remainingLoadingTime = minimumLoadingDuration - elapsedLoadingTime

        if remainingLoadingTime <= 0 {
            shouldShowLoader = false
            self.loaderStartTime = nil
        } else {
            loadingTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(remainingLoadingTime))
                guard !Task.isCancelled else { return }
                shouldShowLoader = false
                self.loaderStartTime = nil
            }
        }
    }
}
