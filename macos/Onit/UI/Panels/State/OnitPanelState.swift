//
//  OnitPanelState.swift
//  Onit
//
//  Created by Kévin Naudin on 28/03/2025.
//

import ApplicationServices
import Combine
import Defaults
import SwiftData
import SwiftUI

@MainActor protocol OnitPanelStateDelegate: AnyObject {
    func panelBecomeKey(state: OnitPanelState)
    func panelResignKey(state: OnitPanelState)
    func panelStateDidChange(state: OnitPanelState)
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?)
}

@MainActor
@Observable
class OnitPanelState: NSObject {
    
    @ObservationIgnored var defaultEnvironmentSource: String? = nil
    
    /// Clients
    let client = FetchingClient()
    let streamingClient = StreamingClient()
    
    /// Container
    let container: ModelContainer = SwiftDataContainer.appContainer
    
    /// States
    let systemPromptState: SystemPromptState = .init()
    var isTyping: Bool = false
    private var isTypingDebounceTask: Task<Void, Never>? = nil
    
    /// ChatView visibility.
    /// When `showChatView` is true the ChatView is rendered;
    /// if `animateChatView` is true, the transition is animated.
    var showChatView: Bool = false
    var animateChatView: Bool = false
    
    /// Services
    var promptSuggestionService: SystemPromptSuggestionService?
    
    // TODO: KNA - Refacto: Should be removed at the end
    var trackedWindow: TrackedWindow? // Used only in Tethered Mode. Corresponds to the specific window that's tethered to the panel.
    var foregroundWindow: TrackedWindow? = nil {
        didSet {
            if let newWindow = foregroundWindow {
                foregroundedWindowHistory.removeAll { $0 == newWindow.hash }
                
                foregroundedWindowHistory.append(newWindow.hash)
                
                if foregroundedWindowHistory.count > 50 {
                    foregroundedWindowHistory.removeFirst()
                }
            }
        }
    } // Used for window context tracking (required for all modes).
    var foregroundedWindowHistory : [UInt?] = []
    
    // TODO: KNA - Refacto: Should be removed at the end
    var trackedScreen: NSScreen?
    var isWindowDragging: Bool = false
    
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
    var hidden: Bool = false {
        didSet {
            notifyDelegates { delegate in
                delegate.panelStateDidChange(state: self)
            }
        }
    }
    var panelWasHidden: Bool = false
    
    var panelMiniaturized: Bool = false {
        didSet {
            notifyDelegates { delegate in
                delegate.panelStateDidChange(state: self)
            }
        }
    }
    
    var tetheredButtonYRelativePosition: CGFloat?
    
    var panelWidth: CGFloat 
    
    var currentChat: Chat?
    var currentPrompts: [Prompt]?
    
    var pendingInstruction = "" {
        didSet {
            if pendingInstruction.isEmpty {
                pendingInstructionCursorPosition = 0
            }
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
    
    var setUpHeight: CGFloat = 0
    
    var generateTask: Task<Void, Never>? = nil
    var generatingPrompt: Prompt?
    var generatingPromptPriorState: GenerationState?
    var generationStopped: Bool = false
    
    /// Don't leave this text empty to ensure the first scroll works.
    var streamedResponse: String = " "
    
    // Web search states
    var webSearchError: Error? = nil
    var isSearchingWeb: [PersistentIdentifier: Bool] = [:]

    typealias WebsiteUrlScrapeTask = Task<Void, Never>
    var websiteUrlsScrapeQueue: [String: WebsiteUrlScrapeTask] = [:]
    
    // Window context states
    typealias UniqueWindowIdentifier = UInt
    var windowContextTasks: [UniqueWindowIdentifier: Task<Void, Never>] = [:]
    
    // Menu States
    var showContextMenu: Bool = false
    var showContextMenuBrowserTabs: Bool = false

    var deleteChatFailed: Bool = false
    
    override init() {
        self.panelWidth = Defaults[.panelWidth]
        super.init()
    }

    init(trackedWindow: TrackedWindow) {
        self.trackedWindow = trackedWindow
        self.panelWidth = Defaults[.panelWidth]
        super.init()
        
        self.promptSuggestionService = SystemPromptSuggestionService(state: self)
    }

    init(screen: NSScreen) {
        self.trackedScreen = screen
        self.panelWidth = Defaults[.panelWidth]
        super.init()
        
        self.promptSuggestionService = SystemPromptSuggestionService(state: self)
    }
    
    // MARK: - Functions
    
    func cancelCurrentAnimation() {
        currentAnimationTask?.cancel()
        currentAnimationTask = nil
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
    
    // MARK: - Functions
    
    func detectIsTyping() {
        isTyping = true
        
        isTypingDebounceTask?.cancel()
        
        isTypingDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(2500))
            
            if !Task.isCancelled {
                await MainActor.run { self.isTyping = false }
            }
        }
    }
}
