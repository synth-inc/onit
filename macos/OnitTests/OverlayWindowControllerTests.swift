import XCTest
@testable import Onit

@MainActor
final class OverlayWindowControllerTests: XCTestCase {
    var model: OnitModel!
    var controller: OverlayWindowController<EmptyView>!

    override func setUp() {
        super.setUp()
        model = OnitModel()
        controller = OverlayWindowController(model: model, content: EmptyView())
    }

    override func tearDown() {
        controller.closeOverlay()
        controller = nil
        model = nil
        super.tearDown()
    }

    func testPanelPositionChangeUpdatesWindowPosition() {
        // Given
        let initialPosition = controller.overlayWindow?.frame.origin

        // When
        Defaults[.panelPosition] = .center
        NotificationCenter.default.post(name: Defaults.didChangeNotification(Defaults.Keys.panelPosition), object: nil)

        // Then
        let newPosition = controller.overlayWindow?.frame.origin
        XCTAssertNotEqual(initialPosition, newPosition, "Window position should change when panel position is updated")
    }
}
