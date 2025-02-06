//
//  AccessibilityPermissionStatus.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

/// Enumeration of the Accessibility permission's status
/// Default status is `.notDetermined`
enum AccessibilityPermissionStatus: Int {
  case notDetermined
  case denied
  case granted
}
