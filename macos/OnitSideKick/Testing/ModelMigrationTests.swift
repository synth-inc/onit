//
//  ModelMigrationTests.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import Defaults
import Foundation

#if DEBUG
    class ModelMigrationTests {
        static func resetToLegacyState(legacyIds: Set<String>) {
            // Reset migration flag
            Defaults[.hasPerformedModelIdMigration] = false

            // Set legacy model IDs
            Defaults[.visibleModelIds] = legacyIds
        }

        static func printMigrationState() {
            print("=== Model Migration State ===")
            print("Has performed migration:", Defaults[.hasPerformedModelIdMigration])
            print("Visible Model IDs:", Defaults[.visibleModelIds])
            print(
                "Available Remote Models:",
                Defaults[.availableRemoteModels].map {
                    "\($0.provider): \($0.id) -> \($0.uniqueId)"
                })
            print("=========================")
        }

        static func testMigration() async {
            // Example legacy state with duplicate model IDs
            let legacyIds: Set<String> = ["gpt-4", "claude-3", "gemini-pro"]

            // Reset to legacy state
            resetToLegacyState(legacyIds: legacyIds)
            print("Before migration:")
            printMigrationState()

            // Let the app perform migration (you'll need to trigger model fetch)
            // This will happen automatically when fetchRemoteModels is called

            print("\nAfter migration:")
            printMigrationState()
        }
    }
#endif
