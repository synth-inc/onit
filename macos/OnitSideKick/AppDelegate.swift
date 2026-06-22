//
//  AppDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import Combine
import Defaults
import FirebaseCore
import FirebaseFirestore
import ServiceManagement
import SwiftUI
import GoogleSignIn

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var keystrokeManager: KeystrokeNotificationManager?
    private var appCoordinator: AppCoordinator?
    private var appModeCoordinator: AppModeCoordinator?
    private var frontmostPidBeforeLaunch: pid_t?

    @MainActor
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Uncomment this if the macOS menu bar (File, Edit, View) appears in the wrong language.
        // This can happen after testing with Xcode's scheme App Language setting (Product → Scheme → Edit Scheme → Run → Options → App Language).
//        Self.clearTestSchemeLanguage()

        frontmostPidBeforeLaunch = NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Tests boot the full Onit.app as their host process. If we let the
        // delegate's real init run, the test bundle's Onit.app registers
        // global hotkeys + CGEventTaps in parallel with the user's real
        // running Onit.app.
        //
        // Skip all delegate-side setup when running under XCTest. Test code
        // that needs subsystems initializes them explicitly via their
        // singletons.
        if TestEnvironment.isRunningTests() {
            log.info("AppDelegate: XCTest detected — skipping delegate setup")
            return
        }

        AppAppearance.applyCurrent()
        FirebaseApp.configure()
        // Use a memory-only Firestore cache: we only write to Firestore from
        // this client, so the default disk cache (which lands in ~/Documents
        // on non-sandboxed macOS and triggers a TCC permission popup) is
        // wasteful for our use case.
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = firestoreSettings
        GIDSignIn.sharedInstance.restorePreviousSignIn()

        // Initialize the app coordinator with the frontmost pid before launch
        appCoordinator = AppCoordinator(frontmostPidAtLaunch: frontmostPidBeforeLaunch)

        // Initialize menu bar.
        self.menuBarController = MenuBarController.shared

        // We need to initialize the keystroke outside of the SwiftUI Application.
        keystrokeManager = KeystrokeNotificationManager.shared

        // Configure dock icon visibility based on user preference
        AppDelegate.configureDockIconVisibility()

        // This is helpful for debugging the new user experience, but should never be committed!
        //        if let appDomain = Bundle.main.bundleIdentifier {
        //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        //            UserDefaults.standard.synchronize()
        //        }

        // Initialize AppModeCoordinator to manage the Panel mode
        appModeCoordinator = AppModeCoordinator.shared
        appModeCoordinator?.delegate = self

        initializeFeatureDisable()

        // Dev build coexistence monitoring (Release builds only)
        #if !DEBUG
        DevBuildDetectionService.shared.startMonitoring()
        KeyboardShortcutsManager.observeDevBuildDetection()
        EscapeKeyManager.shared.observeDevBuildDetection()
        #endif

        checkLaunchOnStartup()
        restoreSession()

        // Launch onboarding for first-time users
        launchOnboardingIfNeeded()
    }

    @MainActor
    private func launchOnboardingIfNeeded() {
        appModeCoordinator?.launchOnboardingIfNeeded()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            AppState.shared.handleDeeplink(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Menu bar app — don't quit when windows close
    }

    func applicationWillTerminate(_ notification: Notification) {
        keystrokeManager?.stopMonitoring()
        appModeCoordinator?.cleanup()
        appCoordinator?.cleanup()
        AnalyticsManager.appQuit()

        // Remove HID remapping to restore normal CapsLock behavior
        KeystrokeNotificationManager.shared.removeHIDRemapping()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Dock-icon click → open the panel.
        PanelStateCoordinator.shared.launchPanel()

        return true
    }

    static func configureDockIconVisibility() {
        let hideDockIcon = Defaults[.hideDockIcon]

        Task { @MainActor in
            if hideDockIcon {
                // Hide the dock icon - app becomes an accessory (background app)
                NSApp.setActivationPolicy(.accessory)
            } else {
                // Show the dock icon - app becomes a regular app
                NSApp.setActivationPolicy(.regular)
            }
        }
    }

    @MainActor
    private func initializeFeatureDisable() {
        // Initialize the unified FeatureDisableManager (triggers observer setup)
        _ = FeatureDisableManager.shared
    }

    @MainActor
    private func checkLaunchOnStartup() {
        if !Defaults[.launchOnStartupRequested] {
            do {
                try SMAppService.mainApp.register()
                Defaults[.launchOnStartupRequested] = true
            } catch {
                print("Error: \(error)")
            }
        }
    }

    @MainActor
    private func restoreSession() {
        if TokenManager.token != nil && AuthManager.shared.account == nil {
            AuthManager.shared.isRestoringSession = true

            Task { @MainActor in
                do {
                    let client = FetchingClient()
                    let account = try await client.getAccount()
                    AuthManager.shared.setAccount(account: account)
                    AnalyticsManager.Identity.identify(account: account)
                } catch {
                    AuthManager.shared.setAccount(account: nil)
                    // `setAccount(nil)` is a no-op for Firebase (the non-nil
                    // branch is the one that calls signIn). Without an
                    // explicit signOut here, a previously cached Firebase
                    // session would survive a failed restoreSession(),
                    // leaving us with `Auth.auth().currentUser` pointing at
                    // an account we can no longer authenticate locally.
                    FirebaseAuthService.shared.signOut()
                    print("Error in `restoreSession()` method in `AppDelegate.swift`: \(error)")
                }

                AuthManager.shared.isRestoringSession = false
            }
        } else {
            AuthManager.shared.isRestoringSession = false
        }
    }

    private static func clearTestSchemeLanguage() {
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    }
}

// MARK: - AppModeCoordinatorDelegate

extension AppDelegate: AppModeCoordinatorDelegate {
    func appModeCoordinator(_ coordinator: AppModeCoordinator, didChangePanelState enabled: Bool) {
        menuBarController?.updateStatusDot()
    }
}
