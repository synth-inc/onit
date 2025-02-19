import XCTest
@testable import Onit

final class PromptGenerationTests: XCTestCase {
    func testRegenerateUpdatesGenerationIndex() {
        // Create a test prompt
        let prompt = Prompt(instruction: "Test instruction", timestamp: .now)

        // Add initial response
        let initialResponse = Response(text: "Initial response", type: .success, model: "test-model")
        prompt.responses.append(initialResponse)
        prompt.generationIndex = 0

        // Add a new response (simulating regeneration)
        let newResponse = Response(text: "New response", type: .success, model: "test-model")
        prompt.responses.append(newResponse)

        // Verify that generationIndex is updated to point to the new response
        XCTAssertEqual(prompt.generationIndex, 1, "Generation index should point to the latest response after regeneration")
        XCTAssertEqual(prompt.responses[prompt.generationIndex].text, "New response", "Current response should be the newly generated one")
    }
}
