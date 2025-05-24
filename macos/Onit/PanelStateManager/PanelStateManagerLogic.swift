//
//  PanelStateManagerLogic.swift
//  Onit
//
//  Created by Kévin Naudin on 07/05/2025.
//

@MainActor
protocol PanelStateManagerLogic {
    
    // MARK: - Properties
    
    var isPanelMovable: Bool { get }
    var defaultState: OnitPanelState { get }
    var state: OnitPanelState { get set }
    var states: [OnitPanelState] { get set }
    
    // MARK: - Functions
    
    func start()
    func stop()
    
    func getState(for windowHash: UInt) -> OnitPanelState?

    func filterHistoryChats(_ chats: [Chat]) -> [Chat]
    func filterPanelChats(_ chats: [Chat]) -> [Chat]
    
    func launchPanel(for state: OnitPanelState)
    func closePanel(for state: OnitPanelState)

    func fetchWindowContext()
}
