//
//  ProcessIdentifier+Helper.swift
//  Onit
//
//  Created by Kévin Naudin on 24/01/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

extension pid_t {
  func getAXUIElement() -> AXUIElement {
    return AXUIElementCreateApplication(self)
  }

  func getAppName() -> String? {
    guard let app = NSRunningApplication(processIdentifier: self) else { return nil }

    return app.localizedName
  }
}
