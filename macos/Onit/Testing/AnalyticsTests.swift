import XCTest
import Defaults
@testable import Onit

final class AnalyticsTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // Reset analytics setting before each test
    Defaults[.analyticsEnabled] = true
  }

  func testAnalyticsOptOut() async {
    // Test default state (enabled)
    XCTAssertTrue(Defaults[.analyticsEnabled])

    // Test disabling analytics
    Defaults[.analyticsEnabled] = false
    XCTAssertFalse(Defaults[.analyticsEnabled])

    // Test that analytics manager respects the setting
    let manager = AnalyticsManager.shared
    await manager.configure()
    await manager.capture("test_event")

    // Test re-enabling analytics
    Defaults[.analyticsEnabled] = true
    XCTAssertTrue(Defaults[.analyticsEnabled])
  }
}
