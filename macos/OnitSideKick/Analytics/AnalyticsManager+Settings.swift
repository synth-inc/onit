//
//  AnalyticsManager+Settings.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct Settings {
        static func opened(on tabName: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["tab_name"] = tabName
            
            PostHogSDK.shared.capture("settings_opened", properties: properties)
        }
        
        static func tabPressed(tabName: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["tab_name"] = tabName
            
            PostHogSDK.shared.capture("settings_tab_selected", properties: properties)
        }
        
        // MARK: - General settings
        
        struct General {
            static func displayModePressed(oldValue: String, newValue: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["old_value"] = oldValue
                properties["new_value"] = newValue
                
                PostHogSDK.shared.capture("settings_general_display_mode", properties: properties)
            }
        }
        
        // MARK: - Models Settings
        
        struct Models {
            static func remoteModelAdded(_ remoteModel: AIModel) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["remote_model_id"] = remoteModel.id
                properties["remote_model_display_name"] = remoteModel.displayName
                properties["remote_model_provider"] = remoteModel.provider.title
                
                PostHogSDK.shared.capture("remote_model_added", properties: properties)
            }
        }
        
        // MARK: - Notification Settings

        struct Notifications {
            /// Tracks when a notification toggle is changed in Settings
            /// - Parameters:
            ///   - notificationType: Which notification was toggled (e.g. "dictation_failed", "mic_disconnected")
            ///   - enabled: Whether the notification is now enabled
            static func toggleChanged(notificationType: String, enabled: Bool) {
                var properties = AnalyticsManager.getCommonProperties()
                properties["notification_type"] = notificationType
                properties["enabled"] = enabled

                PostHogSDK.shared.capture("notification_toggle_changed", properties: properties)
            }
        }

        // MARK: - Auto-Install Updates

        /// Tracks when the auto-install updates toggle is changed
        /// - Parameter enabled: Whether auto-install is now enabled
        static func autoInstallUpdatesToggled(enabled: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            properties["enabled"] = enabled

            PostHogSDK.shared.capture("settings_auto_install_updates_toggled", properties: properties)
        }

        // MARK: - Suggestion Engine Settings
        
        struct SuggestionEngine {
            static func experimentSelected(experimentName: String, experimentBranch: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["experiment_name"] = experimentName
                properties["experiment_branch"] = experimentBranch
                
                PostHogSDK.shared.capture("settings_suggestion_engine_experiment_selected", properties: properties)
            }
        }
    }
}
