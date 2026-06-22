//
//  ExpandingSearchBar.swift
//  Onit
//
//  Created by Loyd Kim on 5/13/26.
//

import SwiftUI

struct ExpandingSearchBar: View {
    // MARK: - Types
    
    struct SizeConfig {
        var cornerRadius: CGFloat = 9
        var searchBarWidth: CGFloat? = 240
    }
    
    struct StatusConfig {
        var shouldCollapseOnEmptyQuery: Bool = true
        var shouldClearQueryOnDisappear: Bool = true
    }
    
    // MARK: - Properties
    
    @Binding var searchQuery: String
    var placeholder: String = String.localized("Search for...", table: "Sidekick")
    var tooltip: String
    var sizeConfig: SizeConfig = .init()
    var statusConfig: StatusConfig = .init()
    
    // MARK: - Observations
    
    @StateObject private var clickOutsideMonitor = ClickOutsideMonitor()
    
    // MARK: - States
    
    @State private var isExpanded: Bool = false
    @State private var searchBarFrameInWindow: CGRect = .zero
    
    // MARK: Private Variables
    
    private var shouldCollapse: Bool {
        return
            !statusConfig.shouldCollapseOnEmptyQuery ||
            searchQuery.isEmpty
    }
    
    // MARK: - Private Functions
    
    private func startClickOutsideMonitor() {
        let frameBinding = $searchBarFrameInWindow
        let isExpandedBinding = $isExpanded
        
        clickOutsideMonitor.onOutsideClick = { outsideClickEvent in
            guard let outsideContentView = outsideClickEvent.window?.contentView
            else {
                return
            }
            
            let appKitLocation = outsideClickEvent.locationInWindow
            let swiftUILocation = CGPoint(
                x: appKitLocation.x,
                y: outsideContentView.frame.height - appKitLocation.y
            )
            let clickedOutside = !frameBinding.wrappedValue.contains(swiftUILocation)
            
            if clickedOutside && shouldCollapse {
                DispatchQueue.main.async {
                    isExpandedBinding.wrappedValue = false
                }
            }
        }
        
        clickOutsideMonitor.startMonitor()
    }

    private func stopClickOutsideMonitor() {
        clickOutsideMonitor.stopMonitor()
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isExpanded {
                searchBarView
            } else {
                iconButtonView
            }
        }
        .onDisappear {
            if statusConfig.shouldClearQueryOnDisappear {
                searchQuery = ""
            }
        }
    }
    
    // MARK: - Child Components: Icon Button View
    
    private var iconButtonView: some View {
        IconButton(
            systemName: "magnifyingglass",
            iconSize: 16,
            buttonSize: 32,
            inactiveColor: Color.S_0,
            hoverBackground: Color.T_9,
            cornerRadius: sizeConfig.cornerRadius,
            tooltipPrompt: tooltip
        ) {
            isExpanded = true
        }
    }
    
    // MARK: - Child Components: Search Bar View
    
    private var searchBarView: some View {
        SearchBar(
            searchQuery: $searchQuery,
            placeholder: placeholder,
            config: SearchBar.config(
                width: sizeConfig.searchBarWidth,
                cornerRadius: sizeConfig.cornerRadius
            ) {
                if shouldCollapse {
                    isExpanded = false
                }
            }
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        searchBarFrameInWindow = proxy.frame(in: .global)
                    }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        searchBarFrameInWindow = newFrame
                    }
            }
        )
        .onAppear {
            startClickOutsideMonitor()
        }
        .onDisappear {
            stopClickOutsideMonitor()
        }
        .onExitCommand {
            searchQuery = ""
            isExpanded = false
        }
    }
}


// MARK: - Click Outside Monitor

private final class ClickOutsideMonitor: ObservableObject {
    private var monitor: Any?
    var onOutsideClick: ((NSEvent) -> Void)?
    
    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @MainActor
    func startMonitor() {
        clearMonitor()
        
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [
                .leftMouseDown,
                .rightMouseDown
            ]
        ) { [weak self] event in
            self?.onOutsideClick?(event)
            return event
        }
    }

    @MainActor
    func stopMonitor() {
        clearMonitor()
    }

    private func clearMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
