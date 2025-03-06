import XCTest
@testable import Onit

final class PanelPositionTests: XCTestCase {
    var model: Model!
    var panel: NSPanel!
    var screen: NSScreen!

    override func setUp() {
        super.setUp()
        model = Model.shared
        screen = NSScreen.main

        // Create a test panel
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        model.panel = panel
    }

    override func tearDown() {
        panel.close()
        panel = nil
        model = nil
        super.tearDown()
    }

    func testPanelPositionUpdate() async {
        guard let screen = screen else {
            XCTFail("No screen available for testing")
            return
        }

        let visibleFrame = screen.visibleFrame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 600

        // Test top left position
        Defaults[.panelPosition] = .topLeft
        await model.updatePanelPosition()
        XCTAssertEqual(
            panel.frame.origin.x,
            visibleFrame.origin.x + 16,
            accuracy: 1.0,
            "Panel should be positioned at the top left"
        )

        // Test top center position
        Defaults[.panelPosition] = .topCenter
        await model.updatePanelPosition()
        XCTAssertEqual(
            panel.frame.origin.x,
            visibleFrame.origin.x + (visibleFrame.width - windowWidth) / 2,
            accuracy: 1.0,
            "Panel should be positioned at the top center"
        )

        // Test top right position
        Defaults[.panelPosition] = .topRight
        await model.updatePanelPosition()
        XCTAssertEqual(
            panel.frame.origin.x,
            visibleFrame.origin.x + visibleFrame.width - windowWidth - 16,
            accuracy: 1.0,
            "Panel should be positioned at the top right"
        )

        // Verify Y position remains consistent
        XCTAssertEqual(
            panel.frame.origin.y,
            visibleFrame.origin.y + visibleFrame.height - windowHeight,
            accuracy: 1.0,
            "Panel Y position should be consistent"
        )
    }
}
