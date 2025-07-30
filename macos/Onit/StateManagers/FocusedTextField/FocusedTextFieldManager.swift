//
//  FocusedTextFieldManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/29/25.
//

import ApplicationServices
import Defaults


@MainActor
class FocusedTextFieldManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = FocusedTextFieldManager()
    
    // MARK: - Constants
    
    private static let textFieldRoles: [String] = [kAXTextFieldRole, kAXTextAreaRole]
    
    @Published var focusedTextField: AXUIElement? = nil
    @Published var focusedTextFieldId: UInt? = nil
    
    // MARK: - Delegates
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    // MARK: - private initializer
    
    private init() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
 
    // MARK: - Delegate Management
    
    func addDelegate(_ delegate: HighlightedTextDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: HighlightedTextDelegate) {
        delegates.remove(delegate)
    }
    
    private func notifyDelegates() {
        for case let delegate as FocusedTextFieldDelegate in delegates.allObjects {
            delegate.focusedTextFieldDidChange(focusedTextField)
        }
    }
    
    func handleFocusedUIElementChanged(for element: AXUIElement) {
        guard let role = element.role(), Self.textFieldRoles.contains(role) else {
            focusedTextFieldId = nil
            focusedTextField = nil
            notifyDelegates()
            return
        }
        
        let elementId: UInt = CFHash(element)
        
        if elementId != focusedTextFieldId {
            self.focusedTextFieldId = elementId
            self.focusedTextField = element
            notifyDelegates()
        }
    }
    
    func handleAppActivation(appName: String?, processID: pid_t) {
        if let mainWindow = processID.firstMainWindow {
            // When we activate a new application, we dont get a focusedUIElementChanged notification, because it hasn't "changed"
            // Instead, we need to scan the hierarchy for the focused elements and then handle it, if found!
            // Note - focusedElements is plural here, because some applications will have many.
            // On my (Tim's) computer Notes gives 21 focusedElements. 20 of the are "AXCell" and one is the "AXTextArea" that we care about.
            let focusedElements = FocusedElementWorker.shared.scanElementHierarchyForAllFocusedElements(window: mainWindow)
        
            if let matchingElement = focusedElements.first(where: { 
                if let role = $0.role() {
                    return Self.textFieldRoles.contains(role)
                }
                return false
            }) {
                self.handleFocusedUIElementChanged(for: matchingElement)
            } else {
                self.focusedTextFieldId = nil
                self.focusedTextField = nil
                notifyDelegates()
            }
        }
    }
}
