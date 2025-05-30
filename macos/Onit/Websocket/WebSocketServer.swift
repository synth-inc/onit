//
//  WebSocketServer.swift
//  Onit
//
//  Created by Kévin Naudin on 29/05/2025.
//

import Foundation
import Network
import SwiftUI

@MainActor
class WebSocketServer: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = WebSocketServer()
    
    // MARK: - Properties
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var connectionBuffers: [ObjectIdentifier: Data] = [:]
    @Published var isRunning = false
    @Published var lastError: String?
    
    private let host = "127.0.0.1"
    private let port: UInt16 = 49442
	private let maxMessageLength: Int = 65536 // 64KB maximum per message
    private let maxMessageSize: Int = 1024 * 1024 // 1MB maximum per message
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func start() {
        guard listener == nil else {
            return
        }
        
        do {
            let wsOptions = NWProtocolWebSocket.Options()
            wsOptions.autoReplyPing = true
            
            let tcpOptions = NWProtocolTCP.Options()
            let parameters = NWParameters(tls: nil, tcp: tcpOptions)
            parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
            parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!
            )
            
            let listener = try NWListener(using: parameters)
            
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleNewConnection(connection)
                }
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    self?.handleListenerStateChange(state)
                }
            }
            
            self.listener = listener
            
            listener.start(queue: .main)
        } catch {
            log.error("Failed to start WebSocket server: \(error)")
            lastError = "Failed to start server: \(error.localizedDescription)"
        }
    }
    
    func stop() {
        log.info("Stopping WebSocket server")
        
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        connectionBuffers.removeAll()
        
        listener?.cancel()
        listener = nil
        
        isRunning = false
    }
    
    // MARK: - Private functions
    
    private func handleListenerStateChange(_ state: NWListener.State) {
        switch state {
        case .ready:
            log.info("WebSocket server is ready and listening on port \(port)")
            isRunning = true
            lastError = nil
        case .failed(let error):
            log.error("WebSocket server failed: \(error)")
            lastError = "Server failed: \(error.localizedDescription)"
            isRunning = false
        case .cancelled:
            log.info("WebSocket server cancelled")
            isRunning = false
        default:
            break
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleConnectionStateChange(connection, state: state)
            }
        }
        connection.start(queue: .main)
        
        receiveMessage(from: connection)
    }
    
    private func handleConnectionStateChange(_ connection: NWConnection, state: NWConnection.State) {
        switch state {
        case .ready:
            log.info("WebSocket connection established & ready")
        case .failed(_):
            removeConnection(connection)
        case .cancelled:
            removeConnection(connection)
        default:
            break
        }
    }
    
    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
        connectionBuffers.removeValue(forKey: ObjectIdentifier(connection))
    }
    
    private func receiveMessage(from connection: NWConnection) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: maxMessageLength,
            completion: { [weak self] data, context, isComplete, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        log.error("Error receiving WebSocket message: \(error)")
                        self.removeConnection(connection)
                        return
                    }
                    
                    if let data = data, !data.isEmpty {
                        self.handleReceivedData(data, from: connection, isComplete: isComplete)
                    }
                    
                    if !isComplete && self.connections.contains(where: { $0 === connection }) {
                        self.receiveMessage(from: connection)
                    }
                }
            }
        )
    }
    
    private func handleReceivedData(_ data: Data, from connection: NWConnection, isComplete: Bool) {
        let connectionId = ObjectIdentifier(connection)
        var buffer = connectionBuffers[connectionId] ?? Data()

        buffer.append(data)
        
        if buffer.count > maxMessageSize {
            log.error("Message size exceeds limit (\(buffer.count) > \(maxMessageSize))")
            connectionBuffers.removeValue(forKey: connectionId)
            
            let response = WebSocketResponse(success: false, message: "Message too large")
            sendResponse(response, to: connection)
            return
        }
        
        if isComplete {
            connectionBuffers.removeValue(forKey: connectionId)
            processReceivedData(buffer, from: connection)
            receiveMessage(from: connection)
        } else {
            connectionBuffers[connectionId] = buffer
        }
    }
    
    private func processReceivedData(_ data: Data, from connection: NWConnection) {
        if let messageString = String(data: data, encoding: .utf8),
           messageString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .contains("disconnect") {
            removeConnection(connection)
            return
        }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            let response = WebSocketResponse(success: true)
            
            sendResponse(response, to: connection)
            processOCRMessage(message.ocrMessage)
        } catch {
            let response = WebSocketResponse(success: false, message: "Invalid message format: \(error.localizedDescription)")
            
            sendResponse(response, to: connection)
        }
    }
    
    private func processOCRMessage(_ ocrMessage: OCRMessage) {
        log.info("Processing OCR: '\(ocrMessage.extractedText)' from '\(ocrMessage.pageTitle)' (\(ocrMessage.pageUrl))")
        
        /// TODO:
        /// - Add Context correctly
        /// - Add some diff
    }
    
    private func sendResponse(_ response: WebSocketResponse, to connection: NWConnection) {
        guard connections.contains(where: { $0 === connection }) else {
            log.warning("Attempted to send response to disconnected client")
            return
        }
        
        do {
            let responseData = try JSONEncoder().encode(response)
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "WebSocket", metadata: [metadata])
            
            connection.send(
                content: responseData,
                contentContext: context,
                isComplete: true,
                completion: .contentProcessed { [weak self] error in
                    if let error = error {
                        log.error("Error sending WebSocket response: \(error)")
                        Task { @MainActor in
                            self?.removeConnection(connection)
                        }
                    }
                }
            )
        } catch {
            log.error("Error encoding WebSocket response: \(error)")
        }
    }
}
