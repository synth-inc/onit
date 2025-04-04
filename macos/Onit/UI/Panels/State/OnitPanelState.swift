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
    
    var activeWindow: AXUIElement?
    var activeWindowPid: pid_t?
    var panel: OnitPanel? {
        didSet {
            isPanelOpened.send(panel != nil)
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
    var isPanelOpened = CurrentValueSubject<Bool, Never>(false)
    var isPanelMiniaturized = CurrentValueSubject<Bool, Never>(false)
    
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
    
    init(activeWindow: AXUIElement?) {
        self.activeWindow = activeWindow
        self.activeWindowPid = activeWindow?.pid()
        super.init()
        
        self.promptSuggestionService = SystemPromptSuggestionService(state: self)
    }
}
