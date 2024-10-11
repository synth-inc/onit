//
//  Codable+Persistence.swift
//
//
//  Created by Benjamin Sage on 3/7/24.
//

import Foundation

extension Optional where Wrapped: Encodable {
    func save(_ key: String? = nil, using userDefaults: UserDefaults = .standard) {
        if let self = self {
            self.save(key, using: userDefaults)
        }
    }
}

extension Optional where Wrapped: Decodable {
    static func load(_ key: String? = nil, using userDefaults: UserDefaults = .standard) -> Optional<Wrapped> {
        return Wrapped.load(key, using: userDefaults)
    }
}

extension Array where Element: Decodable {
    static func load(_ key: String? = nil, using userDefaults: UserDefaults = .standard) -> Array<Element> {
        return Array<Element>.load(key, using: userDefaults) ?? []
    }
}

extension UserDefaults {
    func setCodable<T: Codable>(_ object: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            set(encoded, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }
    
    func codable<T: Codable>(forKey key: String) -> T? {
        if let data = object(forKey: key) as? Data {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }
    
    func clearAll() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    static func clear() {
        standard.clearAll()
    }
}

extension Encodable {
    func save(_ key: String? = nil, using userDefaults: UserDefaults = .standard) {
        let keyToUse = key ?? String(describing: type(of: self))
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            userDefaults.set(encoded, forKey: keyToUse)
        }
    }
}

extension Decodable {
    static func load(_ key: String? = nil, using userDefaults: UserDefaults = .standard) -> Self? {
        let keyToUse = key ?? String(describing: Self.self)
        guard let data = userDefaults.data(forKey: keyToUse) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Self.self, from: data)
    }
}
