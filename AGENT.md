# Onit Agent Guide

## Build/Test Commands
- Build: Open `macos/Onit.xcodeproj` in Xcode or `xcodebuild -project macos/Onit.xcodeproj -scheme Onit -configuration Debug build`
- Test: `xcodebuild -project macos/Onit.xcodeproj -scheme Onit -configuration Debug test`
- Lint: `periphery scan --config macos/.periphery.yml` (dead code analysis)
- Format: `swift-format` with 4-space indentation (see `.swift-format`)
- Clean: `macos/cleanup_app.sh ai.synth.onit` (clears app data for testing)

## Architecture
- **Main app**: `macos/Onit/` - SwiftUI macOS app with AI chat sidebar
- **LLMStream**: `LLMStream/` - Swift package for the view that renders streamed responses from LLMs
- **Server**: `server/` - Backend service (Node.js)
- **Database**: SQLite3 for local storage (TypeaheadHistoryManager)
- **Key components**: Accessibility monitoring, typeahead learning, web context extraction
- **Main entry**: `macos/Onit/App.swift` 

## Code Style
- 4-space indentation (enforced by `.swift-format`)
- Swift naming conventions (camelCase for methods/properties, PascalCase for types)
- Use `// MARK: -` for section organization
- Prefer `Defaults` for user preferences over UserDefaults
- Use `@Default` property wrapper for settings
- Error handling with custom `FetchingError` types
- Extensive use of Swift concurrency (async/await)
- UI testing flags controlled by `Defaults[.collectTypeaheadTestCases]`
