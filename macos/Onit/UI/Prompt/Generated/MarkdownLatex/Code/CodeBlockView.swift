//
//  CodeBlockView.swift
//  Onit
//
//  Created by Kévin Naudin on 09/03/2025.
//
import AppKit
import SwiftUI

class CodeBlockView: NSView {
    // UI Components
    private let titleBar: NSView
    private let languageLabel: NSTextField
    private let copyButton: NSButton
    private let codeContainer: NSView
    private let codeTextView: NSTextView
    private let dividerView: NSView
    
    // Layout constraints
    var codeContainerHeightConstraint: NSLayoutConstraint?
    private var lastCalculatedWidth: CGFloat = 0
    private var heightPreset: Bool = false
    
    // Customizable appearance properties
    var titleBarHeight: CGFloat = 24
    var dividerHeight: CGFloat = 1
    var cornerRadius: CGFloat = 10
    var borderWidth: CGFloat = 1
    var textContainerInsets: NSEdgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    
    // Customizable colors
    var backgroundColor: NSColor {
        get { return NSColor(cgColor: layer?.backgroundColor ?? NSColor.black.withAlphaComponent(0.3).cgColor) ?? .black }
        set { layer?.backgroundColor = newValue.cgColor }
    }
    
    var borderColor: NSColor {
        get { return NSColor(cgColor: layer?.borderColor ?? NSColor.gray.cgColor) ?? .gray }
        set { layer?.borderColor = newValue.cgColor }
    }
    
    init(code: NSAttributedString, language: String?) {
        // Title bar setup
        titleBar = NSView()
        titleBar.wantsLayer = true
        titleBar.layer?.backgroundColor = NSColor(named: "gray700")?.cgColor ?? NSColor.black.withAlphaComponent(0.3).cgColor
        
        // Language label
        languageLabel = NSTextField(labelWithString: language ?? "plain text")
        languageLabel.textColor = NSColor(named: "gray100") ?? .white
        languageLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        
        // Copy button
        copyButton = NSButton(title: "Copy", target: nil, action: nil)
        copyButton.bezelStyle = .rounded
        copyButton.controlSize = .small
        copyButton.font = .systemFont(ofSize: 11)
        
        // Divider
        dividerView = NSView()
        dividerView.wantsLayer = true
        dividerView.layer?.backgroundColor = NSColor(named: "gray700")?.cgColor ?? NSColor.gray.cgColor
        
        // Code container setup
        codeContainer = NSView()
        codeContainer.wantsLayer = true
        codeContainer.layer?.backgroundColor = NSColor(named: "gray700")?.cgColor ?? NSColor.black.withAlphaComponent(0.3).cgColor
        
        // Code text view setup
        let textStorage = NSTextStorage(attributedString: code)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = true
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Create text view
        codeTextView = NSTextView(frame: .zero, textContainer: textContainer)
        codeTextView.isEditable = false
        codeTextView.isSelectable = true
        codeTextView.backgroundColor = .clear
        codeTextView.drawsBackground = false
        codeTextView.textContainerInset = .zero
        codeTextView.isVerticallyResizable = true
        codeTextView.isHorizontallyResizable = false
        codeTextView.autoresizingMask = [.width]
        codeTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        codeTextView.minSize = NSSize(width: 0, height: 0)
        codeTextView.textColor = .white
        codeTextView.alignment = .left
        
        // Important: Set the text storage after configuration
        if let textView = codeTextView.textStorage {
            textView.setAttributedString(code)
        }
        
        // Force layout
        layoutManager.ensureLayout(for: textContainer)
        
        super.init(frame: .zero)
        
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(named: "gray700")?.cgColor ?? NSColor.black.withAlphaComponent(0.3).cgColor
        layer?.cornerRadius = cornerRadius
        layer?.borderWidth = borderWidth
        layer?.borderColor = NSColor(named: "gray700")?.cgColor ?? NSColor.gray.cgColor
        layer?.masksToBounds = true
        
        // Disable autoresizing mask translation
        translatesAutoresizingMaskIntoConstraints = false
        
        titleBar.addSubview(languageLabel)
        titleBar.addSubview(copyButton)
        
        codeContainer.addSubview(codeTextView)
        
        addSubview(titleBar)
        addSubview(dividerView)
        addSubview(codeContainer)
        
        // Configure content priorities
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        // Configure subviews priorities
        titleBar.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleBar.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        dividerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dividerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        codeContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Configure text view priorities
        codeTextView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func calculateTextHeight(forWidth width: CGFloat) -> CGFloat {
        guard let layoutManager = codeTextView.layoutManager,
              let container = codeTextView.textContainer else {
            return 0
        }
        
        // Calculate available width
        let horizontalInsets = textContainerInsets.left + textContainerInsets.right
        let availableWidth = max(width - horizontalInsets, 100) // Ensure minimum width and account for padding
        
        // Update container width
        container.size = NSSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
        
        // Force layout
        layoutManager.ensureLayout(for: container)
        
        // Get text height
        let textRect = layoutManager.usedRect(for: container)
        
        return textRect.height
    }
    
    private func setupConstraints() {
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        codeContainer.translatesAutoresizingMaskIntoConstraints = false
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create height constraint with initial height
        codeContainerHeightConstraint = codeContainer.heightAnchor.constraint(equalToConstant: 100)
        codeContainerHeightConstraint?.priority = .defaultHigh
        codeContainerHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            // Title bar constraints
            titleBar.topAnchor.constraint(equalTo: topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: titleBarHeight),
            
            // Language label constraints
            languageLabel.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            languageLabel.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor, constant: 12),
            
            // Copy button constraints
            copyButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor, constant: -8),
            
            // Divider constraints
            dividerView.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: dividerHeight),
            
            // Code container constraints
            codeContainer.topAnchor.constraint(equalTo: dividerView.bottomAnchor),
            codeContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            codeContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            codeContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Code text view constraints
            codeTextView.topAnchor.constraint(equalTo: codeContainer.topAnchor, constant: textContainerInsets.top),
            codeTextView.leadingAnchor.constraint(equalTo: codeContainer.leadingAnchor, constant: textContainerInsets.left),
            codeTextView.trailingAnchor.constraint(equalTo: codeContainer.trailingAnchor, constant: -textContainerInsets.right),
            codeTextView.bottomAnchor.constraint(equalTo: codeContainer.bottomAnchor, constant: -textContainerInsets.bottom)
        ])
    }
    
    private func setupActions() {
        copyButton.target = self
        copyButton.action = #selector(copyCodeToPasteboard)
    }
    
    @objc private func copyCodeToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(codeTextView.string, forType: .string)
        
        // Visual feedback
        copyButton.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.title = "Copy"
        }
    }
    
    override var intrinsicContentSize: NSSize {
        let totalHeight = titleBarHeight + dividerHeight + (codeContainerHeightConstraint?.constant ?? 100)
        
        return NSSize(width: NSView.noIntrinsicMetric, height: totalHeight)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        if let superview = superview {
            // Add width constraint to match superview width
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalTo: superview.widthAnchor)
            ])
            
            let initialWidth = superview.bounds.width
            
            if initialWidth > 0 {
                updateHeight(forWidth: initialWidth)
            }
        }
    }
    
    private func updateHeight(forWidth width: CGFloat) {
        guard !heightPreset else { return }
        
        let textHeight = calculateTextHeight(forWidth: width)
        let verticalInsets = textContainerInsets.top + textContainerInsets.bottom
        let totalHeight = textHeight + verticalInsets
        
        // Update height constraint
        if abs(codeContainerHeightConstraint?.constant ?? 0 - totalHeight) > 1 {
            codeContainerHeightConstraint?.constant = totalHeight
            
            // Force layout update
            needsLayout = true
            layoutSubtreeIfNeeded()
            
            // Notify superview that our size has changed
            invalidateIntrinsicContentSize()
            superview?.needsLayout = true
        }
        
        lastCalculatedWidth = width
    }
    
    override func layout() {
        super.layout()
        
        guard !heightPreset else { return }
        
        let currentWidth = bounds.width
        if currentWidth > 0 && abs(currentWidth - lastCalculatedWidth) > 1 {
            updateHeight(forWidth: currentWidth)
        }
    }
    
    // Method to preset the height and avoid recalculations
    func presetHeight(_ height: CGFloat) {
        if let constraint = codeContainerHeightConstraint {
            constraint.constant = height
            heightPreset = true

            invalidateIntrinsicContentSize()
        }
    }
} 
