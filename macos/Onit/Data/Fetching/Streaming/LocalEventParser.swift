//
//  LocalEventParser.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Foundation
import EventSource

public struct LocalEvent: EVEvent {
    public var id: String?
    public var event: String?
    public var data: String?
    public var other: [String: String]?
    public var time: String?
}

struct LocalEventParser: EventParser {
    private var buffer = Data()
    
    static let rk: UInt8 = 0x7D // }
    static let lf: UInt8 = 0x0A // \n
    
    mutating func parse(_ data: Data) -> [any EVEvent] {
        let (separatedMessages, remainingData) = splitBuffer(for: buffer + data)
        buffer = remainingData
        return parseBuffer(for: separatedMessages)
    }
    
    private func parseBuffer(for rawMessages: [Data]) -> [EVEvent] {
        // Parse data to ServerMessage model
        let messages: [LocalEvent] = rawMessages.compactMap {
            LocalEvent(data: String(data: $0, encoding: .utf8))
        }

        return messages
    }
    
    private func splitBuffer(for data: Data) -> (completeData: [Data], remainingData: Data) {
        let separator: [UInt8] = [Self.rk, Self.lf]
        var rawMessages = [Data]()

        // If event separator is not present do not parse any unfinished messages
        guard let lastSeparator = data.lastRange(of: separator) else {
            return ([], data)
        }

        let bufferRange = data.startIndex..<lastSeparator.upperBound - 1
        let remainingRange = lastSeparator.upperBound..<data.endIndex
        
        rawMessages = data[bufferRange].split(separator: separator)
        
        return (rawMessages, data[remainingRange])
    }
}
