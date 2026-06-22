//
//  TestEnvironment.swift
//  Onit
//
//  Shared helper to detect when code is running under XCTest.
//

import Foundation

enum TestEnvironment {
    static func isRunningTests() -> Bool {
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil { return true }
        return NSClassFromString("XCTest") != nil
    }
}


