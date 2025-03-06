import XCTest
@testable import Onit
import Defaults

final class PanelTests: XCTestCase {
    var model: Model!

    override func setUp() {
        super.setUp()
        model = Model()
    }

    override func tearDown() {
        model = nil
        super.tearDown()
    }

    func testPanelOpensOnMouseMonitorWhenEnabled() {
        // Enable the feature
        Defaults[.openOnMouseMonitor] = true

        // Create a mock mouse location
        let mockMouseLocation = NSPoint(x: 1000, y: 500)
        let mockScreen = NSScreen()
        mockScreen.frame = NSRect(x: 800, y: 0, width: 1920, height: 1080)

        // Mock NSScreen.screens to return our mock screen
        NSScreen.screens = [mockScreen]

        // Mock NSEvent.mouseLocation to return our mock location
        NSEvent.mouseLocation = mockMouseLocation

        // Show the panel
        model.showPanel()

        // Verify the panel is on the correct screen
        XCTAssertNotNil(model.panel)
        XCTAssertEqual(model.panel?.screen, mockScreen)
    }

    func testPanelOpensOnMainMonitorWhenDisabled() {
        // Disable the feature
        Defaults[.openOnMouseMonitor] = false

        // Create a mock mouse location on a different screen
        let mockMouseLocation = NSPoint(x: 1000, y: 500)
        let mockMainScreen = NSScreen()
        mockMainScreen.frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let mockSecondaryScreen = NSScreen()
        mockSecondaryScreen.frame = NSRect(x: 1920, y: 0, width: 1920, height: 1080)

        // Mock NSScreen.screens and NSScreen.main
        NSScreen.screens = [mockMainScreen, mockSecondaryScreen]
        NSScreen.main = mockMainScreen

        // Mock NSEvent.mouseLocation to return our mock location
        NSEvent.mouseLocation = mockMouseLocation

        // Show the panel
        model.showPanel()

        // Verify the panel is on the main screen
        XCTAssertNotNil(model.panel)
        XCTAssertEqual(model.panel?.screen, mockMainScreen)
    }
}
