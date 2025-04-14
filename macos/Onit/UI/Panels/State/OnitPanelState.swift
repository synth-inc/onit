//
//  OnitPanelState.swift
//  Onit
//
//  Created by Kévin Naudin on 28/03/2025.
//

import ApplicationServices
import Combine
import SwiftData
import SwiftUI

@MainActor protocol OnitPanelStateDelegate: AnyObject {
    func panelBecomeKey(state: OnitPanelState)
    func panelStateDidChange(state: OnitPanelState)
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?)
}

@MainActor
@Observable
class OnitPanelState: NSObject {
    
    /// Clients
    let client = FetchingClient()
    let streamingClient = StreamingClient()
    
    /// Container
    let container: ModelContainer = SwiftDataContainer.appContainer
    
    /// States
    let systemPromptState: SystemPromptState = .init()
    
    /// Services
    var promptSuggestionService: SystemPromptSuggestionService?
    
    var trackedWindow: TrackedWindow?
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    var currentAnimationTask: Task<Void, Never>?
    
    var panel: OnitPanel? {
        didSet {
            let opened = panel != nil
            
            if _panelOpened != opened {
                _panelOpened = opened
            }
        }
    }
    var panelOpened: Bool = false {
        didSet {
            notifyDelegates { delegate in
                delegate.panelStateDidChange(state: self)
            }
        }
    }
    var panelMiniaturized: Bool = false {
        didSet {
            notifyDelegates { delegate in
                delegate.panelStateDidChange(state: self)
            }
        }
    }
    
    var tetheredButtonYPosition: CGFloat?
    
    var currentChat: Chat?
    var currentPrompts: [Prompt]?
    
    var pendingInstruction = "" {
        didSet {
            notifyDelegateInputsChange()
        }
    }
    var pendingInstructionCursorPosition: Int = 0
    var pendingContextList: [Context] = [] {
        didSet {
            notifyDelegateInputsChange()
        }
    }
    var pendingInput: Input? = nil {
        didSet {
            notifyDelegateInputsChange()
        }
    }
    
    var systemPromptId: String = SystemPrompt.outputOnly.id
    
    var imageUploads: [URL: UploadProgress] = [:]
    var uploadTasks: [URL: Task<URL?, Never>] = [:]
    
    var textFocusTrigger = false
    
    var showFileImporter = false
    var showHistory: Bool = false
    var historyIndex = -1
    
    var headerHeight: CGFloat = 0
    var inputHeight: CGFloat = 0
    var setUpHeight: CGFloat = 0
    var systemPromptHeight: CGFloat = 0
    
    var generateTask: Task<Void, Never>? = nil
    var generatingPrompt: Prompt?
    var generatingPromptPriorState: GenerationState?
    
    var streamedResponse: String = ""
    
    // Web search state
    var webSearchError: Error? = nil
    var isSearchingWeb: [PersistentIdentifier: Bool] = [:]

    typealias WebsiteUrlScrapeTask = Task<Void, Never>
    var websiteUrlsScrapeQueue: [String: WebsiteUrlScrapeTask] = [:]

    var deleteChatFailed: Bool = false
    
    init(trackedWindow: TrackedWindow?) {
        self.trackedWindow = trackedWindow
        super.init()
        
        self.promptSuggestionService = SystemPromptSuggestionService(state: self)
    }
    
    // MARK: - Delegates
    
    func addDelegate(_ delegate: OnitPanelStateDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: OnitPanelStateDelegate) {
        delegates.remove(delegate)
    }
    
    func notifyDelegates(_ notification: (OnitPanelStateDelegate) -> Void) {
        for case let delegate as OnitPanelStateDelegate in delegates.allObjects {
            notification(delegate)
        }
    }
    
    private func notifyDelegateInputsChange() {
        notifyDelegates { delegate in
            delegate.userInputsDidChange(
                instruction: pendingInstruction,
                contexts: pendingContextList,
                input: pendingInput
            )
        }
    }
}
