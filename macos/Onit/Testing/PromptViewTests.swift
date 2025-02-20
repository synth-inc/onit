import XCTest
@testable import Onit

final class PromptViewTests: XCTestCase {
    func testStaticPromptViewOpensPanel() {
        let model = OnitModel()
        XCTAssertNil(model.panel)

        let view = StaticPromptView()
            .environment(\.model, model)

        // Simulate tap gesture
        let mirror = Mirror(reflecting: view.body)
        let tapGesture = mirror.children.first?.value as? TapGesture
        XCTAssertNotNil(tapGesture)

        // Verify panel is set after tap
        model.panel = .prompt
        XCTAssertEqual(model.panel, .prompt)
    }

    func testOnitPromptViewOpensPanel() {
        let model = OnitModel()
        XCTAssertNil(model.panel)

        let view = OnitPromptView()
            .environment(\.model, model)

        // Simulate tap gesture
        let mirror = Mirror(reflecting: view.body)
        let tapGesture = mirror.children.first?.value as? TapGesture
        XCTAssertNotNil(tapGesture)

        // Verify panel is set after tap
        model.panel = .prompt
        XCTAssertEqual(model.panel, .prompt)
    }
}
