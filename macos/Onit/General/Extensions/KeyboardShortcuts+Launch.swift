//
//  KeyboardShortcuts+Launch.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let launch = Self("launch", default: .init(.zero, modifiers: [.command]))
  static let launchWithAutoContext = Self(
    "launchWithAutoContext", default: .init(.zero, modifiers: [.shift, .command]))
  static let escape = Self("escape", default: .init(.escape))
  static let enter = Self("enter", default: .init(.return, modifiers: []))
  static let newChat = Self("newChat", default: .init(.nine, modifiers: [.command]))
  static let resizeWindow = Self("resizeWindow", default: .init(.eight, modifiers: [.command]))
  static let toggleLocalMode = Self(
    "toggleLocalMode", default: .init(.seven, modifiers: [.shift, .command]))
}
