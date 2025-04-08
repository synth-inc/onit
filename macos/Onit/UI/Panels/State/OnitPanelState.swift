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
    func panelStateDidChange(state: OnitPanelState, isOpened: Bool, isMiniaturized: Bool)
}

@MainActor
@Observable
class OnitPanelState: NSObject {
    
    /// Clients
    let client = FetchingClient()
    let streamingClient = StreamingClient()
    
    /// Container
    let container: ModelContainer = SwiftDataContainer.appContainer
    
    /// Services
    var promptSuggestionService: SystemPromptSuggestionService?
    
    var trackedWindow: TrackedWindow?
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    var _panelOpened: Bool = false {
        didSet {
            notifyDelegates()
        }
    }
    private var _panelMiniaturized: Bool = false {
        didSet {
            notifyDelegates()
        }
    }
    
    var isOpened: Bool {
        get { return _panelOpened }
    }
    
    var isMiniaturized: Bool {
        get { return _panelMiniaturized }
    }
    
    var panel: OnitPanel? {
        didSet {
            let opened = panel != nil
            
            if _panelOpened != opened {
                _panelOpened = opened
            }
        }
    }
    
    func setPanelMiniaturized(_ value: Bool) {
        if _panelMiniaturized != value {
            _panelMiniaturized = value
        }
    }
    
    var currentChat: Chat?
    var currentPrompts: [Prompt]?
    
    var pendingInstruction = "" {
        didSet {
            pendingInstructionSubject.send(pendingInstruction)
        }
    }
    var pendingInstructionCursorPosition: Int = 0
    var pendingContextList: [Context] = [] {
        didSet {
            pendingContextListSubject.send(pendingContextList)
        }
    }
    var pendingInput: Input? = nil {
        didSet {
            pendingInputSubject.send(pendingInput)
        }
    }
    
    var pendingInstructionSubject = CurrentValueSubject<String, Never>("")
    var pendingContextListSubject = CurrentValueSubject<[Context], Never>([])
    var pendingInputSubject = CurrentValueSubject<Input?, Never>(nil)
    
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
    
    private func notifyDelegates() {
        for case let delegate as OnitPanelStateDelegate in delegates.allObjects {
            delegate.panelStateDidChange(state: self, isOpened: _panelOpened, isMiniaturized: _panelMiniaturized)
        }
    }
}
