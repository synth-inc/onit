import XCTest
@testable import Onit
import Defaults
import SwiftData

@MainActor
final class PanelTests: XCTestCase {
    var model: OnitModel!
    var container: ModelContainer!

    override func setUp() async throws {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Chat.self, configurations: config)
        model = OnitModel()
        model.container = container
    }

    override func tearDown() {
        model = nil
        container = nil
        super.tearDown()
    }

    func testPanelOpensOnMouseMonitorWhenEnabled() async throws {
        // Enable the feature
        Defaults[.openOnMouseMonitor] = true

        // Create a mock screen setup
        let mockMainScreen = NSScreen.main!
        let mockSecondaryScreen = NSScreen(frame: NSRect(x: mockMainScreen.frame.width, y: 0, width: 1920, height: 1080))
        let mouseLocation = NSPoint(x: mockMainScreen.frame.width + 100, y: 500)

        // Show the panel
        model.showPanel()

        // Wait for the panel to be created and positioned
        try await Task.sleep(for: .milliseconds(100))

        // Verify the panel exists and is positioned correctly
        XCTAssertNotNil(model.panel)

        // The panel should be positioned on the secondary screen since that's where the mouse is
        let panelFrame = model.panel!.frame
        XCTAssertGreaterThan(panelFrame.origin.x, mockMainScreen.frame.width)
    }

    func testPanelOpensOnMainMonitorWhenDisabled() async throws {
        // Disable the feature
        Defaults[.openOnMouseMonitor] = false

        // Create a mock screen setup
        let mockMainScreen = NSScreen.main!
        let mockSecondaryScreen = NSScreen(frame: NSRect(x: mockMainScreen.frame.width, y: 0, width: 1920, height: 1080))
        let mouseLocation = NSPoint(x: mockMainScreen.frame.width + 100, y: 500)

        // Show the panel
        model.showPanel()

        // Wait for the panel to be created and positioned
        try await Task.sleep(for: .milliseconds(100))

        // Verify the panel exists and is positioned correctly
        XCTAssertNotNil(model.panel)

        // The panel should be positioned on the main screen even though the mouse is on the secondary screen
        let panelFrame = model.panel!.frame
        XCTAssertLessThan(panelFrame.origin.x, mockMainScreen.frame.width)
    }
}
