import Defaults
import FirebaseCore
import PostHog
import Foundation

@MainActor
class AnalyticsManager: ObservableObject {
  static let shared = AnalyticsManager()

  @Default(.analyticsEnabled) var analyticsEnabled

  private var isConfigured = false

  func configure() {
    guard analyticsEnabled else {
      // If analytics are disabled, don't configure anything
      return
    }

    // Configure Firebase
    FirebaseApp.configure()

    // Configure PostHog
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogApiKey") as? String,
      let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String
    else {
      print("PostHog -> Error not initialized due to missing API key or host")
      return
    }

    let config = PostHogConfig(apiKey: apiKey, host: host)
    PostHogSDK.shared.setup(config)
    isConfigured = true
  }

  func capture(_ event: String, properties: [String: Any]? = nil) {
    guard analyticsEnabled, isConfigured else {
      return
    }
    PostHogSDK.shared.capture(event, properties: properties)
  }

  func isFeatureEnabled(_ flag: String) -> Bool {
    guard analyticsEnabled, isConfigured else {
      return false
    }
    return PostHogSDK.shared.isFeatureEnabled(flag)
  }

  func getFeatureFlag(_ flag: String) -> Any? {
    guard analyticsEnabled, isConfigured else {
      return nil
    }
    return PostHogSDK.shared.getFeatureFlag(flag)
  }
}
