//
//  MenuBarController.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit
import Combine
import Defaults
import Observation

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    // MARK: - Singleton
    
    static let shared = MenuBarController()
    
    // MARK: - Properties
    
    private let menuBarOnit: NSStatusItem
    private var menu: NSMenu

    // MARK: - Initializer
    
    override init() {
        /// Adding Onit to the menu bar.
        self.menuBarOnit = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        
        self.menu = NSMenu()
        
        super.init()
        
        self.menu.delegate = self
        self.addWindowChangeDelegate()
        self.shouldShowCheckForPermissionsItem = self.anyPermissionMissing
        self.addOnitEntryPointToMenuBar()
        self.populateMenu()
        
        // Observer for status changes
        NotificationCenter.default.publisher(for: AppState.statusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusDot()
                self?.populateMenu()
            }
            .store(in: &self.cancellables)
        
        Defaults.publisher(.featureDisableRules)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.featureDisableStatus = FeatureDisableManager.shared.currentDisableStatus(for: .menuDefault)
                self?.populateMenu()
            }
            .store(in: &self.cancellables)

        Defaults.publisher(.enableSidebar)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.showMenuBarOpenPanelItem = state.newValue
                self?.populateMenu()
            }
            .store(in: &self.cancellables)
        
        Defaults.publisher(.tetheredButtonHideAllAppsTimerDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tetheredButtonHideAllAppsTimerDate = state.newValue
            }
            .store(in: &self.cancellables)
        
        Defaults.publisher(.tetheredButtonHideAllApps)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tetheredButtonHideAllApps = state.newValue
            }
            .store(in: &self.cancellables)
        
        self.accessibilityPermissionManager.$accessibilityPermissionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.shouldShowCheckForPermissionsItem = self?.anyPermissionMissing ?? false
            }
            .store(in: &self.cancellables)
        
    }
    
    // MARK: - Conformance to `NSMenuDelegate`
    
    func menuWillOpen(_ menu: NSMenu) {
        self.isMenuOpen = true
        self.featureDisableStatus = FeatureDisableManager.shared.currentDisableStatus(for: .menuDefault)
        self.shouldShowCheckForPermissionsItem = self.anyPermissionMissing
        self.populateMenu()
        self.updateStatusDot()
    }

    func menuDidClose(_ menu: NSMenu) {
        self.isMenuOpen = false
        self.appStatusItemRef?.removeSubscriptions()
        self.appStatusItemRef = nil
    }
    
    // MARK: - States: Defaults
    
    private var cancellables = Set<AnyCancellable>()
    private var showMenuBarOpenPanelItem: Bool = Defaults[.enableSidebar]
    private var tetheredButtonHideAllAppsTimerDate: Date? = Defaults[.tetheredButtonHideAllAppsTimerDate]
    private var tetheredButtonHideAllApps: Bool = Defaults[.tetheredButtonHideAllApps]
    // MARK: - States
    
    private weak var appStatusItemRef: MenuBarAppStatus? = nil
    private var isMenuOpen: Bool = false
    
    private var featureDisableStatus: FeatureDisableStatus? = nil
    private var windowChangeDelegate: AccessibilityNotificationsDelegate? = nil
    private var foregroundWindow: TrackedWindow? = nil
    private var shouldShowCheckForPermissionsItem: Bool? = nil
    
    private var statusDot: CAShapeLayer? = nil
    
    // MARK: - Private Variables
    
    private let accessibilityNotificationsManager = AccessibilityNotificationsManager.shared
    private let accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    private var accessibilityNotGranted: Bool {
        return self.accessibilityPermissionManager.accessibilityPermissionStatus != .granted
    }

    private var anyPermissionMissing: Bool {
        return self.accessibilityNotGranted
    }
    
    private var isHideAllAppsTimerActive: Bool {
        guard let timerDate = self.tetheredButtonHideAllAppsTimerDate else { return false }
        return timerDate > Date()
    }
    
    private var shouldShowHideTimerStatus: Bool {
        return self.isHideAllAppsTimerActive || self.tetheredButtonHideAllApps
    }
    
    private var isOnitDisabled: Bool {
        return self.featureDisableStatus != .notDisabled || self.tetheredButtonHideAllApps || self.isHideAllAppsTimerActive
    }
    
    // MARK: - Private Functions: Status Dot
    
    private func cropIconForStatusDot(
        icon: NSImage,
        cropSize: CGFloat
    ) -> NSImage {
        let croppedIconSize = NSSize(
            width: 16,
            height: 16
        )
        
        let croppedIcon = NSImage(
            size: croppedIconSize,
            flipped: false
        ) { rect in
            var drawRect = rect
            let iconSize = icon.size
            
            if iconSize.width > 0 && iconSize.height > 0 {
                let iconAspectRatio = iconSize.width / iconSize.height
                let canvasAspectRatio = rect.width / rect.height
                
                if iconAspectRatio > canvasAspectRatio {
                    let width = rect.width
                    let height = width / iconAspectRatio
                    
                    drawRect = CGRect(
                        x: rect.minX,
                        y: rect.midY - height / 2,
                        width: width,
                        height: height
                    )
                } else {
                    let height = rect.height
                    let width = height * iconAspectRatio
                    
                    drawRect = CGRect(
                        x: rect.midX - width / 2,
                        y: rect.minY,
                        width: width,
                        height: height
                    )
                }
            }
            
            NSGraphicsContext.current?.imageInterpolation = .high
            icon.draw(in: drawRect)
            
            guard let context = NSGraphicsContext.current?.cgContext else { return true }
            context.saveGState()
            context.setBlendMode(.clear)
            
            let inset: CGFloat = 2
            
            let centerPosition = CGPoint(
                x: rect.maxX - inset,
                y: rect.minY + inset
            )
            
            let cropRect = CGRect(
                x: centerPosition.x - cropSize / 2,
                y: centerPosition.y - cropSize / 2,
                width: cropSize,
                height: cropSize
            )
            
            context.fillEllipse(in: cropRect)
            context.restoreGState()
            return true
        }
        
        croppedIcon.isTemplate = icon.isTemplate
        return croppedIcon
    }
    
    private func determineStatusDotColor() -> NSColor {
        return AppState.shared.statusDotColor.nsColor
    }
    
    private func ensureStatusDotExists() {
        guard let iconButton = self.menuBarOnit.button else { return }
        
        if iconButton.layer == nil {
            iconButton.wantsLayer = true
        }
        iconButton.layer?.isOpaque = false
        
        if self.statusDot == nil {
            let dot = CAShapeLayer()
            dot.fillColor = self.determineStatusDotColor().cgColor
            dot.zPosition = 1
            iconButton.layer?.addSublayer(dot)
            self.statusDot = dot
        }
    }
    
    private func drawStatusDot() {
        guard let iconButton = self.menuBarOnit.button,
              let statusDot = self.statusDot
        else {
            return
        }
        
        /// Static values
        let iconSize: CGFloat = 16
        let statusDotSize: CGFloat = 6
        let spacingBeforeTitleText: CGFloat = iconButton.title.isEmpty ? 0 : 2
        let font = iconButton.font ?? NSFont.systemFont(ofSize: 11, weight: .semibold)
        
        let titleTextWidth: CGFloat = iconButton.title.isEmpty ? 0 : (iconButton.title as NSString).size(
            withAttributes: [.font: font]
        ).width
        
        let totalMenuIconWidth: CGFloat = iconSize + (iconButton.title.isEmpty ? 0 : spacingBeforeTitleText + titleTextWidth)
        
        /// Positioning
        let statusDotXPositionBase: CGFloat = (iconButton.bounds.midX - totalMenuIconWidth / 2)  + iconSize
        let statusDotYPositionBase: CGFloat = (iconButton.bounds.height - iconSize) * 2
        let inset: CGFloat = 2
        let statusDotRadius = statusDotSize / 2
        
        let statusDotXPosition = statusDotXPositionBase - inset
        let statusDotYPosition = statusDotYPositionBase + inset + statusDotRadius
        
        let statusDotPosition = CGPoint(
            x: statusDotXPosition,
            y: statusDotYPosition
        )
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        statusDot.bounds = CGRect(
            x: 0,
            y: 0,
            width: statusDotSize,
            height: statusDotSize
        )
        
        statusDot.path = CGPath(
            ellipseIn: CGRect(
                origin: .zero,
                size: statusDot.bounds.size
            ),
            transform: nil
        )
        
        statusDot.position = statusDotPosition
        
        CATransaction.commit()
    }
    
    func updateStatusDot() {
        // TEMP: status dot hidden for now (see addOnitEntryPointToMenuBar)
        // self.ensureStatusDotExists()
        // self.statusDot?.fillColor = self.determineStatusDotColor().cgColor
        // self.drawStatusDot()
    }
    
    // MARK: - Private Functions: Window Delegate
    
    private func onWindowChange(info: WindowChangeInfo) {
        self.foregroundWindow = info.trackedWindow
        self.featureDisableStatus = FeatureDisableManager.shared.currentDisableStatus(for: .menuDefault)
    }
    
    private func addWindowChangeDelegate() {
        let windowChangeDelegate = WindowChangeDelegate(
            onWindowChange: self.onWindowChange
        )
        accessibilityNotificationsManager.addDelegate(windowChangeDelegate)
        self.windowChangeDelegate = windowChangeDelegate
    }
    
    // MARK: - Private Functions: Menu Bar Items
    
    private func addOnitEntryPointToMenuBar() {
        #if ONIT_BETA
        let iconName = "noodle-beta"
        #else
        let iconName = "noodle"
        #endif

        if  let button = self.menuBarOnit.button,
            let icon = NSImage(named: iconName)?.copy() as? NSImage
        {
            // TEMP: cropSize 0 = no hole carved for the status dot (dot hidden)
            let iconWithStatusDotCrop = self.cropIconForStatusDot(icon: icon, cropSize: 0)
            button.image = iconWithStatusDotCrop
            button.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            button.wantsLayer = true
            self.updateStatusDot()
        }
    }
    
    private func addMenuItem(
        _ item: NSMenuItem,
        target: AnyObject? = nil
    ) {
        item.target = target ?? item /// Falling back to `item` here because most menu bar items are designed to be self-contained, so th   ey should target themselves.
        
        self.menu.addItem(item)
    }
    
    private func addMenuDivider() {
        self.menu.addItem(.separator())
    }
    
    private func addAppStatusItem() {
        let appStatusItem = MenuBarAppStatus()
        self.appStatusItemRef = appStatusItem
        self.addMenuItem(appStatusItem)
        appStatusItem.runPostInitilizationSetup()
    }
    
    private func showOrHideFeatureDisableItems() {
        if let featureDisableStatus = self.featureDisableStatus,
           Defaults[.enableSidebar]
        {
            switch featureDisableStatus {
            case .notDisabled:
                if let foregroundWindow = self.foregroundWindow {
                    let featureDisableInAppItem = MenuBarFeatureDisable(foregroundWindow: foregroundWindow)
                    self.addMenuItem(featureDisableInAppItem)
                    featureDisableInAppItem.runPostInitilizationSetup()
                }
                
                let featureDisableEverywhereItem = MenuBarFeatureDisable()
                self.addMenuItem(featureDisableEverywhereItem)
                featureDisableEverywhereItem.runPostInitilizationSetup()
                self.addMenuDivider()
            default:
                let featureEnableItem = MenuBarFeatureEnable()
                self.addMenuItem(featureEnableItem)
                featureEnableItem.runPostInitilizationSetup()
                self.addMenuDivider()
            }
        }
    }
    
    private func showOrHideCheckForPermissionsItem() {
        if let shouldShowCheckForPermissionsItem = self.shouldShowCheckForPermissionsItem,
           shouldShowCheckForPermissionsItem == true
        {
            let checkForPermissionsItem = MenuBarCheckForPermissions()
            self.addMenuItem(checkForPermissionsItem)
            checkForPermissionsItem.runPostInitilizationSetup()
            self.addMenuDivider()
        }
    }
    
    private func showOrHideOpenPanelItem() {
        if self.showMenuBarOpenPanelItem {
            let openPanelItem = MenuBarOpenPanel()
            self.addMenuItem(openPanelItem)
            openPanelItem.runPostInitilizationSetup()
        }
    }
    
    private func showOrHideHideTimerStatus() {
        if self.shouldShowHideTimerStatus {
            let hideTimerStatusItem = MenuBarHideTimerStatus(
                isHideAllAppsTimerActive: self.isHideAllAppsTimerActive
            )
            self.addMenuItem(hideTimerStatusItem)
            hideTimerStatusItem.runPostInitilizationSetup()
        }
    }
    
    private func populateMenu() {
        self.menu.removeAllItems()

        self.addAppStatusItem()
        self.addMenuDivider()

//        let versionItem = MenuBarVersion()
//        self.addMenuItem(versionItem)
//        versionItem.runPostInitilizationSetup()

        let appItem = MenuBarApp()
        self.addMenuItem(appItem)
        appItem.runPostInitilizationSetup()

        self.addMenuDivider()

        self.showOrHideFeatureDisableItems()

        self.showOrHideCheckForPermissionsItem()
        self.showOrHideHideTimerStatus()
        self.showOrHideOpenPanelItem()
        self.addMenuDivider()
        
        let discordItem = MenuBarDiscord()
        self.addMenuItem(discordItem)
        discordItem.runPostInitilizationSetup()
        
        let checkForUpdatesItem = MenuBarCheckForUpdates()
        self.addMenuItem(checkForUpdatesItem)
        checkForUpdatesItem.runPostInitilizationSetup()
        
        self.addMenuDivider()

        let quitItem = MenuBarQuit()
        self.addMenuItem(quitItem)
        quitItem.runPostInitilizationSetup()

        self.menuBarOnit.menu = self.menu
    }
}
