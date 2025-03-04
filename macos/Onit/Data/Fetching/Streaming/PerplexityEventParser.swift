//
//  PerplexityEventParser.swift
//  Onit
//
//  Created by Kévin Naudin on 04/03/2025.
//

import Foundation
import EventSource

struct PerplexityEventParser: EventParser {
    private let mode: EventSource.Mode
    private var buffer = Data()

    init(mode: EventSource.Mode = .default) {
        self.mode = mode
    }

    static let lf: UInt8 = 0x0A
    static let cr: UInt8 = 0x0D

    mutating func parse(_ data: Data) -> [EVEvent] {
        let (separatedMessages, remainingData) = splitBuffer(for: buffer + data)
        buffer = remainingData
        return parseBuffer(for: separatedMessages)
    }

    private func parseBuffer(for rawMessages: [Data]) -> [EVEvent] {
        // Parse data to ServerMessage model
        let messages: [ServerEvent] = rawMessages.compactMap { ServerEvent.parse(from: $0, mode: mode) }

        return messages
    }

    private func splitBuffer(for data: Data) -> (completeData: [Data], remainingData: Data) {
        let separator: [UInt8] = [Self.cr, Self.lf, Self.cr, Self.lf]
        var rawMessages = [Data]()

        // If event separator is not present do not parse any unfinished messages
        guard let lastSeparator = data.lastRange(of: separator) else { return ([], data) }

        let bufferRange = data.startIndex..<lastSeparator.upperBound
        let remainingRange = lastSeparator.upperBound..<data.endIndex

        rawMessages = data[bufferRange].split(separator: separator)

        return (rawMessages, data[remainingRange])
    }
}
