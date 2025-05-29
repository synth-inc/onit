//
//  TokenManager.swift
//  Onit
//
//  Created by Jason Swanson on 4/23/25.
//

import Foundation
import CryptoKit

struct TokenError: Error {
    enum ErrorType {
        case encryption
        case decryption
        case keyGeneration
        case storage
    }
    
    let type: ErrorType
    let underlyingError: Error?
    
    init(_ type: ErrorType, _ error: Error? = nil) {
        self.type = type
        self.underlyingError = error
    }
}

struct TokenManager {
    private static let tokenFileName = "token.enc"
    private static let keyFileName = "encryption.key"
    
    public static var token: String? {
        get { try? getToken() }
        set { try? setToken(newValue) }
    }
    
    private static func setToken(_ newToken: String?) throws {
        if let token = newToken {
            try encryptAndSaveToken(token)
        } else {
            remove()
        }
    }
    
    private static func legacyFetchToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "inc.synth.Onit.auth",
            kSecAttrAccount as String: "token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)

        if status == errSecSuccess {
            if let retrievedData = out as? Data,
               let token = String(data: retrievedData, encoding: .utf8) {
                return token
            }
        }

        return nil
    }

    
    private static func getToken() throws -> String? {
        guard FileManager.default.fileExists(atPath: tokenFileURL.path) else {
            if let legacyToken = legacyFetchToken() {
                try setToken(legacyToken)
                return legacyToken
            } else {
                return nil
            }
        }
        
        do {
            let encryptedData = try Data(contentsOf: tokenFileURL)
            let key = try getKey()
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            guard let token = String(data: decryptedData, encoding: .utf8) else {
                throw TokenError(.decryption)
            }
            
            return token
        } catch {
            throw TokenError(.decryption, error)
        }
    }

    private static func encryptAndSaveToken(_ token: String) throws {
        do {
            guard let data = token.data(using: .utf8) else {
                throw TokenError(.encryption)
            }
            
            let key = try getKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let encryptedData = sealedBox.combined else {
                throw TokenError(.encryption)
            }
            
            try encryptedData.write(to: tokenFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            throw TokenError(.encryption, error)
        }
    }

    private static var appSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("Onit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var tokenFileURL: URL {
        appSupportDirectory.appendingPathComponent(tokenFileName)
    }

    private static var keyFileURL: URL {
        appSupportDirectory.appendingPathComponent(keyFileName)
    }

    private static func getKey() throws -> SymmetricKey {
        do {
            if FileManager.default.fileExists(atPath: keyFileURL.path) {
                let keyData = try Data(contentsOf: keyFileURL)
                return SymmetricKey(data: keyData)
            }

            let key = SymmetricKey(size: .bits256)
            try saveKey(key)
            return key
        } catch {
            throw TokenError(.keyGeneration, error)
        }
    }

    private static func saveKey(_ key: SymmetricKey) throws {
        do {
            let keyData = key.withUnsafeBytes { Data($0) }
            try keyData.write(to: keyFileURL, options: [.completeFileProtection, .atomic])
        } catch {
            throw TokenError(.storage, error)
        }
    }

    @discardableResult
    private static func remove() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: tokenFileURL.path) {
                try FileManager.default.removeItem(at: tokenFileURL)
            }
            return true
        } catch {
            return false
        }
    }
}
