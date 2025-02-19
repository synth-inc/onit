import XCTest
@testable import Onit

final class RegenerationTests: XCTestCase {
    func testRegenerationRemovesSubsequentResponses() {
        // Create a prompt with multiple responses
        let prompt = Prompt(instruction: "Test prompt", timestamp: .now)
        prompt.responses = [
            Response(text: "Response 1", type: .success),
            Response(text: "Response 2", type: .success),
            Response(text: "Response 3", type: .success)
        ]
        prompt.generationIndex = 1 // Set current index to second response

        // Create model and generate new response
        let model = OnitModel()
        model.generate(prompt)

        // Verify that responses after current index were removed
        XCTAssertEqual(prompt.responses.count, 2, "Responses after current index should be removed")
        XCTAssertEqual(prompt.responses[0].text, "Response 1", "First response should remain")
        XCTAssertEqual(prompt.responses[1].text, "Response 2", "Second response should remain")
        XCTAssertEqual(prompt.generationIndex, 1, "Generation index should remain at current position")
    }
}
