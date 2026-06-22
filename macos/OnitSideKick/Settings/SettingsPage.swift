//
//  SettingsPage.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import Defaults
import SwiftUI

enum SettingsPage: CaseIterable, Codable, Defaults.Serializable {
    // MARK: - Cases

    case general
    case accountAndBilling
    case setup
    case memories
//    case shortcuts
    case about

    case disabledAppsAndSites

    case panelBehavior
    case panelModels
    case panelPrompts
    case panelShortcuts
    case panelContext
    case panelWebSearch

    #if DEBUG || ONIT_BETA
    case experimental
    case sidekickDatabase
    case sidekickDebug
    #endif

    // MARK: - CaseIterable

    static var rootCases: [SettingsPage] {
        return [
            .general,
            .accountAndBilling,
            .setup,
            .memories,
            .about
        ]
    }

    /// Panel (Sidebar)-specific pages
    static var panelCases: [SettingsPage] {
        return [
            .panelBehavior,
            .panelModels,
            .panelPrompts,
            .panelShortcuts,
            .panelContext,
            .panelWebSearch,
            .disabledAppsAndSites
        ]
    }

    #if DEBUG || ONIT_BETA
    /// Development pages (DEBUG/BETA only)
    static var devCases: [SettingsPage] {
        return [
            .experimental,
            .sidekickDatabase,
            .sidekickDebug
        ]
    }
    #endif

    // MARK: - Variables

    @MainActor
    var name: String {
        switch self {
        case .general:
            return String.localized("General", table: "Settings")
        case .accountAndBilling:
            return String.localized("Account & Billing", table: "Settings")
        case .setup:
            return String.localized("Setup", table: "Settings")
        case .memories:
            return String.localized("Memories", table: "Settings")
//        case .shortcuts:
//            return String.localized("Shortcuts", table: "Settings")
        case .about:
            return String.localized("About", table: "Settings")

        case .disabledAppsAndSites:
            return String.localized("Disabled Apps", table: "Settings")

        case .panelBehavior:
            return String.localized("General", table: "Settings")
        case .panelModels:
            return String.localized("Models", table: "Settings")
        case .panelPrompts:
            return String.localized("Prompts", table: "Settings")
        case .panelShortcuts:
            return String.localized("Shortcuts", table: "Settings")
        case .panelContext:
            return String.localized("Context", table: "Settings")
        case .panelWebSearch:
            return String.localized("Web Search", table: "Settings")

        #if DEBUG || ONIT_BETA
        case .experimental:
            return String.localized("Experimental", table: "Settings")
        case .sidekickDatabase:
            return String.localized("Sidekick - Database", table: "Settings")
        case .sidekickDebug:
            return String.localized("Sidekick - Debug", table: "Settings")
        #endif
        }
    }

    var hasCustomScrolling: Bool {
        switch self {
        case .panelPrompts:
            return true
        default:
            return false
        }
    }

    /// Pages that render their own custom title bar (with inline action buttons)
    /// in their own body, opting out of `SettingsWindowPages`' default header.
    var rendersOwnHeader: Bool {
        switch self {
        default:
            return false
        }
    }

    var icon: String {
        switch self {
        /// Root
        case .general:
            return "gearshape.fill"
        case .accountAndBilling:
            return "person.fill"
        case .setup:
            return "hammer.fill"
        case .memories:
            return "brain"
        case .about:
            return "info.circle.fill"
        case .disabledAppsAndSites:
            return "hourglass.tophalf.filled"
        /// Sidekick
        case .panelBehavior:
            return "gearshape.fill"
        case .panelModels:
            return "cpu.fill"
        case .panelPrompts:
            return "bubble.fill"
        case .panelShortcuts:
            return "keyboard.fill"
        case .panelContext:
            return "lightbulb.fill"
        case .panelWebSearch:
            return "magnifyingglass"
        /// Dev
        #if DEBUG || ONIT_BETA
        case .experimental,
                .sidekickDatabase,
                .sidekickDebug:
            return "gearshape.fill"
        #endif
        }
    }

    /// URL path segment for deep linking via `onit-sidekick://settings/<deepLinkPath>`.
    var deepLinkPath: String {
        switch self {
        case .general: return "general"
        case .accountAndBilling: return "account"
        case .setup: return "setup"
        case .memories: return "memories"
        case .about: return "about"
        case .disabledAppsAndSites: return "disabled-apps"
        case .panelBehavior: return "sidekick"
        case .panelModels: return "sidekick-models"
        case .panelPrompts: return "sidekick-prompts"
        case .panelShortcuts: return "sidekick-shortcuts"
        case .panelContext: return "sidekick-context"
        case .panelWebSearch: return "sidekick-web-search"
        #if DEBUG || ONIT_BETA
        case .experimental: return "experimental"
        case .sidekickDatabase: return "sidekick-database"
        case .sidekickDebug: return "sidekick-debug"
        #endif
        }
    }

    var iconBackgroundColor: Color {
        switch self {
        case .setup,
                .about,
                .panelModels,
                .panelPrompts,
                .panelShortcuts,
                .panelContext,
                .panelWebSearch:
            return Color.blue

        case .disabledAppsAndSites:
            return Color.blue350

        case .accountAndBilling:
            return Color.green

        case .memories:
            return Color.purple

        #if DEBUG || ONIT_BETA
        case .experimental,
                .sidekickDatabase,
                .sidekickDebug:
            return Color.gray
        #endif

        default:
            return Color.gray
        }
    }
}
