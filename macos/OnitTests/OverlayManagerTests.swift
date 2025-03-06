import XCTest
@testable import Onit

final class OverlayManagerTests: XCTestCase {
    var manager: OverlayManager!

    override func setUp() {
        super.setUp()
        manager = OverlayManager.shared
    }

    override func tearDown() {
        manager.dismissOverlay()
        super.tearDown()
    }

    func testPanelPositionUpdateTriggersOverlayUpdate() {
        // Given
        let expectation = XCTestExpectation(description: "Panel position update")
        let testView = Text("Test")
        let model = OnitModel()

        // When
        manager.showOverlay(model: model, content: testView)

        // Verify initial position
        let initialPosition = Defaults[.panelPosition]

        // Change panel position
        let newPosition: PanelPosition = initialPosition == .center ? .topRight : .center
        Defaults[.panelPosition] = newPosition

        // Then
        // Wait a bit for the notification to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Get the current overlay window position
            if let overlayWindow = self.manager.currentOverlay?.overlayWindow {
                let screenFrame = NSScreen.main?.visibleFrame ?? .zero
                let windowFrame = overlayWindow.frame

                switch newPosition {
                case .center:
                    // Check if window is roughly in the center
                    let expectedX = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
                    let expectedY = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2
                    XCTAssertEqual(windowFrame.origin.x, expectedX, accuracy: 1.0)
                    XCTAssertEqual(windowFrame.origin.y, expectedY, accuracy: 1.0)
                case .topRight:
                    // Check if window is in the top right corner
                    let expectedX = screenFrame.maxX - windowFrame.width - 20
                    let expectedY = screenFrame.maxY - windowFrame.height - 20
                    XCTAssertEqual(windowFrame.origin.x, expectedX, accuracy: 1.0)
                    XCTAssertEqual(windowFrame.origin.y, expectedY, accuracy: 1.0)
                default:
                    break // Other positions not tested in this case
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
