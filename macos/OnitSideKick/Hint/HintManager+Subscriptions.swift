//
//  HintManager+Subscriptions.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions
 * Private Functions: Defaults Subscriptions
 * Private Functions: Publisher Subscriptions
 * Private Functions: Observer Subscriptions
 */

import Defaults
import Foundation

extension HintManager {
    // MARK: - Public Functions
    
    func setupSubscriptions() {
        setupDefaultsSubscriptions()
        setupPublisherSubscriptions()
        setupObserverSubscriptions()
        
        // Observe dev build detection (Release builds only)
        #if !DEBUG
        DevBuildDetectionService.shared.$isDevBuildRunning
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.evaluateVisibility()
            }
            .store(in: &cancellables)
        #endif
    }
    
    // MARK: - Private Functions: Defaults Subscriptions
    
    private func setupDefaultsSubscriptions() {
        Defaults.publisher(.enableSidebar)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.evaluateVisibility()
            }
            .store(in: &cancellables)

        Defaults.publisher(.alwaysHideHint)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.evaluateVisibility()
            }
            .store(in: &cancellables)
        
        Defaults.publisher(.showHintAccessibilityAlert)
              .removeDuplicates()
              .sink { [weak self] _ in
                  guard let self = self else { return }
                  self.updateActivePopUpType()
                  self.evaluateVisibility()
              }
              .store(in: &cancellables)

        /// Commented out for now until non-AX becomes the default state.
//        Defaults.publisher(.showHintScreenRecordingAlert)
//          .removeDuplicates()
//          .sink { [weak self] _ in
//              guard let self = self else { return }
//              self.updateActivePopUpType()
//              self.evaluateVisibility()
//          }
//          .store(in: &cancellables)

        Defaults.publisher(.showHintUpdateAvailableAlert)
          .removeDuplicates()
          .sink { [weak self] _ in
              guard let self = self else { return }
              self.updateActivePopUpType()
              self.evaluateVisibility()
          }
          .store(in: &cancellables)

        Defaults.publisher(.dismissedUpdateAlertVersion)
          .removeDuplicates()
          .sink { [weak self] _ in
              guard let self = self else { return }
              self.updateActivePopUpType()
              self.evaluateVisibility()
          }
          .store(in: &cancellables)
    }
    
    // MARK: - Private Functions: Publisher Subscriptions
    
    private func setupPublisherSubscriptions() {
        AccessibilityPermissionManager.shared.$accessibilityPermissionStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateActivePopUpType()
                self.evaluateVisibility()
            }
            .store(in: &cancellables)
  
        /// Commented out for now until non-AX becomes the default state.
//        ScreenRecordingPermissionManager.shared.$isScreenRecordingEnabled
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                self.updateActivePopUpType()
//                self.evaluateVisibility()
//            }
//            .store(in: &cancellables)
        
        OnboardingWindowManager.shared.$onboardingWindowIsVisible
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateActivePopUpType()
                self.evaluateVisibility()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Functions: Observer Subscriptions
    
    private func setupObserverSubscriptions() {
        observeUpdateAvailability()
    }
    
    private func observeUpdateAvailability() {
        withObservationTracking {
            _ = AppState.shared.isUpdateAvailable
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateActivePopUpType()
                self.evaluateVisibility()
                self.observeUpdateAvailability()
            }
        }
    }
}
