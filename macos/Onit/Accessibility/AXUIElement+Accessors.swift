//
//  AXUIElement+Accessors.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

@preconcurrency import ApplicationServices

extension AXUIElement {
    func attribute(forAttribute attribute: CFString) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, attribute, &value)
        if result == .success {
            return value
        } else {
            return nil
        }
    }
    
    func value() -> String? {
        return self.attribute(forAttribute: kAXValueAttribute as CFString) as? String
    }
    
    func position() -> CGPoint? {
        let position = self.attribute(forAttribute: kAXPositionAttribute as CFString)
        if let position = position {
            var cgPoint = CGPoint()
            AXValueGetValue(position as! AXValue, .cgPoint, &cgPoint)
            return cgPoint
        } else {
            return nil
        }
    }
    
    func size() -> CGSize? {
        let size = self.attribute(forAttribute: kAXSizeAttribute as CFString)
        if let size = size {
            var cgSize = CGSize()
            AXValueGetValue(size as! AXValue, .cgSize, &cgSize)
            return cgSize
        } else {
            return nil
        }
    }

    func frame() -> CGRect? {
        if let position = self.position(), let size = self.size() {
            return CGRect(origin: position, size: size)
        } else {
            return nil
        }
    }
    
    func role() -> String? {
        return self.attribute(forAttribute: kAXRoleAttribute as CFString) as? String
    }
    
    func description() -> String? {
        return self.attribute(forAttribute: kAXDescriptionAttribute as CFString) as? String
    }
    
    func subrole() -> String? {
        return self.attribute(forAttribute: kAXSubroleAttribute as CFString) as? String
    }
    
    func title() -> String? {
        return self.attribute(forAttribute: kAXTitleAttribute as CFString) as? String
    }

    func children() -> [AXUIElement]? {
        return self.attribute(forAttribute: kAXChildrenAttribute as CFString) as? [AXUIElement]
    }

    func visibleChildren() -> [AXUIElement]? {
        return self.attribute(forAttribute: kAXVisibleChildrenAttribute as CFString) as? [AXUIElement]
    }
    
    func selectedTextBound() -> CGRect? {
        var rangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success else {
            return nil
        }
        
        var textRange = CFRange()
        AXValueGetValue(rangeValue as! AXValue, .cfRange, &textRange)
        
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            self,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue as CFTypeRef,
            &bounds
        ) == .success else {
            return nil
        }
        
        let boundsValue = bounds as! AXValue
        
        var rect = CGRect.zero
        AXValueGetValue(boundsValue, .cgRect, &rect)
        
        return rect
    }
}

//
//    public func position() -> CGPoint? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXPositionAttribute,error: &error) as? CGPoint
//    }
//    
//    public func setPosition(point:CGPoint) -> AXError {
//        return self.set(attributeKey: kAXPositionAttribute, value: point)
//    }
//    
//    public func size() -> CGSize? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSizeAttribute,error: &error) as? CGSize
//    }
//    
//    public func setSize(size:CGSize) -> AXError {
//        return self.set(attributeKey: kAXSizeAttribute, value: size)
//    }
//    
//    public func frame() -> CGRect? {
//        if let orgin = self.position(),let size = self.size(){
//            return CGRect.init(origin: orgin, size: size)
//        }
//        return nil
//    }
//    
//    public func setFrame(rect:CGRect)  {
//        _ = setPosition(point: rect.origin)
//        _ = setSize(size: rect.size)
//    }
//    
//    public func setFrame(origin:CGPoint, size:CGSize)  {
//        _ = setPosition(point: origin)
//        _ = setSize(size: size)
//    }
//    
//    
//    public func isMinimized() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMinimizedAttribute,error: &error) as? Bool
//    }
//    
//    
//    public func minimized(_ isMinimized:Bool) -> AXError {
//        self.set(attributeKey: kAXMinimizedAttribute, value: isMinimized)
//    }
//    
//    public func isFullScreen() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXFullscreenAttribute,error: &error) as? Bool
//    }
//    
//    public func fullScreen() -> AXError {
//        self.set(attributeKey: kAXFullscreenAttribute, value: kCFBooleanTrue as Any)
//    }
//    
//    public func title() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXTitleAttribute,error: &error) as? String
//    }
//    
//    public func setTitle(title:String) -> AXError {
//        return self.set(attributeKey: kAXTitleAttribute, value: title as CFString)
//    }
//    
//    public func role() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRoleAttribute,error: &error) as? String
//    }
//    
//    public func subRole() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSubroleAttribute,error: &error) as? String
//    }
//    
//    public func roleDescription() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRoleDescriptionAttribute,error: &error) as? String
//    }
//    
//    public func help() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHelpAttribute,error: &error) as? String
//    }
//    
//    public func valueAttribute() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXValueAttribute,error: &error) as? String
//    }
//    
//    public func valueDescriptionAttribute() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXValueDescriptionAttribute,error: &error) as? String
//    }
//    
//    public func minValue() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMinValueAttribute,error: &error)
//    }
//    
//    public func maxValue() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMaxValueAttribute,error: &error)
//    }
//    
//    public func valueIncrement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXValueIncrementAttribute,error: &error)
//    }
//    
//    public func allowedValues() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXAllowedValuesAttribute,error: &error)
//    }
//    
//    public func placeholderValue() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXPlaceholderValueAttribute,error: &error) as? String
//    }
//    
//    public func enabled() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXEnabledAttribute,error: &error) as? Bool
//    }
//    
//    public func busy() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXElementBusyAttribute,error: &error) as? Bool
//    }
//    
//    public func focused() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXFocusedAttribute,error: &error) as? Bool
//    }
//    
//    public func parent() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXParentAttribute,error: &error)
//    }
//    
//    public func children() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return  self.value(attributeKey: kAXChildrenAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func selectedChildren() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return  self.value(attributeKey: kAXSelectedChildrenAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func visibleChildren() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return  self.value(attributeKey: kAXVisibleChildrenAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func window() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXWindowAttribute,error: &error)
//    }
//    
//    public func topLevelUIElement() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXTopLevelUIElementAttribute,error: &error)
//    }
//    
//    public func orientation() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXOrientationAttribute,error: &error) as? String
//    }
//    
//    public func descriptionAttributetation() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDescriptionAttribute,error: &error) as? String
//    }
//    
//    public func description() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDescription,error: &error) as? String
//    }
//    
//    public func selectedText() -> String? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSelectedTextAttribute,error: &error) as? String
//    }
//    
//    public func selectedTextRange() -> CFRange? {
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXSelectedTextRangeAttribute,error: &error){
//            let axValue : AXValue = value as! AXValue
//            return axValue.cfRange()
//        }
//        return nil
//    }
//    
//    public func selectedTextRange() -> [CFRange]? {
//        var result = [CFRange]()
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXSelectedTextRangesAttribute,error: &error){
//            let axValues = value as! [AXValue]
//            for axValue in axValues {
//                if let range = axValue.cfRange(){
//                    result.append(range)
//                }
//                
//            }
//        }
//        return result
//    }
//    
//    public func visibleCharacterRange() -> CFRange? {
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXVisibleCharacterRangeAttribute,error: &error){
//            let axValue : AXValue = value as! AXValue
//            return axValue.cfRange()
//        }
//        return nil
//    }
//    
//    public func numberOfCharacters() -> CFNumber? {
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXNumberOfCharactersAttribute,error: &error){
//            let cfNumberValue : CFNumber = value as! CFNumber
//            return cfNumberValue
//        }
//        return nil
//        
//    }
//    
//    public func sharedTextUIElements() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSharedTextUIElementsAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func sharedCharacterRange() -> CFRange? {
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXSharedCharacterRangeAttribute,error: &error){
//            let axValue : AXValue = value as! AXValue
//            return axValue.cfRange()
//        }
//        return nil
//    }
//    
//    public func sharedFocusElements() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSharedFocusElementsAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func insertionPointLineNumber() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXInsertionPointLineNumberAttribute,error: &error)
//    }
//    
//    public func isMain() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMainAttribute,error: &error) as? Bool
//    }
//    
//    public func closeButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXCloseButtonAttribute,error: &error)
//    }
//    
//    public func zoomBotton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXZoomButtonAttribute,error: &error)
//    }
//    
//    public func minimizeBotton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMinimizeButtonAttribute,error: &error)
//    }
//    
//    public func toolbarButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMinimizeButtonAttribute,error: &error)
//    }
//    
//    public func fullScreenButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXFullScreenButtonAttribute,error: &error)
//    }
//    
//    /// A convenience attribute so assistive apps can quickly access a window's document proxy element.
//    ///  Writable? No.
//    /// - Returns: Value: An AXUIElementRef of the window's document proxy element.
//    public func proxy() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXProxyAttribute,error: &error)
//    }
//    
//    /// A convenience attribute so assistive apps can quickly access a window's grow area element. Required for all window elements that have a grow area.
//    ///  Writable? No.
//    /// - Returns: Value: An AXUIElementRef of the window's grow area element.
//    public func growArea() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXGrowAreaAttribute,error: &error)
//    }
//    
//    /// Whether a window is modal.
//    ///  Required for all window elements.
//    ///  Writable? No.
//    /// - Returns: A Bool. True means the window is modal.
//    public func isModal() -> Bool? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXModalAttribute,error: &error) as? Bool
//    }
//    
//    ///  A convenience attribute so assistive apps can quickly access a window's default button element, if any.
//    ///  Writable? No.
//    ///  Required for all window elements that have a default button.
//    /// - Returns: Value: An AXUIElementRef of the window's default button element.
//    public func defaultButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXDefaultButtonAttribute,error: &error)
//    }
//    
//    ///  A convenience attribute so assistive apps can quickly access a window's cancel button element, if any.
//    ///  Writable? No.
//    ///  Writable? No.
//    /// - Returns: Value: An AXUIElementRef of the window's cancel button element.
//    public func cancelButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXCancelButtonAttribute,error: &error)
//    }
//
//    // MARK: menu-specific attributes
//    public func menuItemCmdChar() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemCmdCharAttribute,error: &error)
//    }
//    
//    public func menuItemCmdVirtualKey() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemCmdVirtualKeyAttribute,error: &error)
//    }
//    
//    public func menuItemCmdGlyph() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemCmdGlyphAttribute,error: &error)
//    }
//    
//    public func menuItemCmdModifiers() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemCmdModifiersAttribute,error: &error)
//    }
//    
//    public func menuItemMarkChar() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemMarkCharAttribute,error: &error)
//    }
//    
//    public func menuItemPrimaryUIElement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMenuItemPrimaryUIElementAttribute,error: &error)
//    }
//    
//    // MARK: application-specific attributes
//    public func menuBar() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMenuBarAttribute, error: &error)
//    }
//    
//    public func windows() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXWindowsAttribute,error: &error) as? [AXUIElement]
//        
//    }
//    
//    public func frontmost() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXFrontmostAttribute,error: &error)
//    }
//    
//    public func hidden() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHiddenAttribute, error: &error)
//    }
//    
//    public func mainWindow() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMainWindowAttribute,error: &error)
//    }
//    
//    public func focusedWindow() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXFocusedWindowAttribute,error: &error)
//    }
//    
//    public func focusedUIElement() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXFocusedUIElementAttribute,error: &error)
//    }
//    
//    public func extrasMenuBar() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXExtrasMenuBarAttribute,error: &error)
//    }
//    
//    
//    /// A convenience attribute whose value is an element that is a header for another element. For example, an outline element has a header attribute whose value is a element of role AXGroup that contains the header buttons for each column.Used for things like tables, outlines, columns, etc.
//    /// Recommended for elements that have header elements contained within them that an assistive application might want convenient access to.
//    ///  Writable? No.
//    /// - Returns: An AXUIElementRef whose role varies.
//    public func kAXHeaderAttribute() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMainWindowAttribute,error: &error)
//    }
//    
//    public func edited() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXEditedAttribute,error: &error)
//    }
//    
//    
//    public func valueWraps() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXValueWrapsAttribute, error: &error)
//    }
//    
//    public func tabs() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXTabsAttribute, error: &error)
//    }
//    
//    public func titleUIElement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXTitleUIElementAttribute, error: &error)
//    }
//    
//    public func horizontalScrollBar() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHorizontalScrollBarAttribute, error: &error)
//    }
//    
//    public func verticalScrollBar() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVerticalScrollBarAttribute, error: &error)
//    }
//    
//    public func overflowButton() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXOverflowButtonAttribute, error: &error)
//    }
//    
//    public func filename() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXFilenameAttribute, error: &error)
//    }
//    
//    public func expanded() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXExpandedAttribute, error: &error)
//    }
//    
//    public func selected() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSelectedAttribute, error: &error)
//    }
//    
//    public func splitters() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSplittersAttribute, error: &error)
//    }
//    
//    public func nextContents() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXNextContentsAttribute, error: &error)
//    }
//    
//    public func document() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDocumentAttribute, error: &error)
//    }
//    
//    public func decrementButton() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDecrementButtonAttribute, error: &error)
//    }
//    
//    public func incrementButton() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXIncrementButtonAttribute, error: &error)
//    }
//    
//    public func previousContents() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXPreviousContentsAttribute, error: &error)
//    }
//    
//    public func contents() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXContentsAttribute, error: &error) as? [AXUIElement]
//    }
//    
//    public func incrementor() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXIncrementorAttribute, error: &error)
//    }
//    
//    public func hourField() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXHourFieldAttribute, error: &error)
//    }
//    
//    public func minuteField() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMinuteFieldAttribute, error: &error)
//    }
//    
//    public func secondField() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXSecondFieldAttribute, error: &error)
//    }
//    
//    public func AXAMPMField() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXAMPMFieldAttribute, error: &error)
//    }
//    
//    public func dayFieldAttribute() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXDayFieldAttribute, error: &error)
//    }
//    
//    public func monthFieldAttribute() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXMonthFieldAttribute, error: &error)
//    }
//    
//    public func yearFieldAttribute() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXYearFieldAttribute, error: &error)
//    }
//    
//    public func columnTitle() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnTitleAttribute,error: &error)
//    }
//    
//    
//    ///  Required for elements that represent a disk or network item.
//    ///  Writable? No.
//    /// - Returns: Value: A CFURLRef.
//    public func URL() -> CFURL? {
//        var error : AXError = AXError.failure
//        if let value = self.value(attributeKey: kAXColumnTitleAttribute, error: &error){
//            let urlValue : CFURL = value as! CFURL
//            return urlValue
//        }
//        return nil
//    }
//    
//    
//    public func labelUIElements() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLabelUIElementsAttribute,error: &error)
//    }
//    
//    public func labelValue() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLabelValueAttribute,error: &error)
//    }
//    
//    public func shownMenuUIElement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXShownMenuUIElementAttribute,error: &error)
//    }
//    
//    public func servesAsTitleForUIElements() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXServesAsTitleForUIElementsAttribute,error: &error)
//    }
//    
//    public func linkedUIElements() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLinkedUIElementsAttribute,error: &error)
//    }
//    //MARK: table/outline view attributes
//    public func rows() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRowsAttribute,error: &error)
//    }
//    
//    public func visibleRows() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVisibleRowsAttribute,error: &error)
//    }
//    
//    public func selectedRows() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSelectedRowsAttribute,error: &error)
//    }
//    
//    public func columns() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnsAttribute,error: &error)
//    }
//    
//    ///  Indicates the visible column sub-elements of a kAXBrowserRole element.This is the subset of a browser's kAXColumnsAttribute where each column in thearray is one that is currently scrolled into view within the browser. It doesnot  include any columns that are currently scrolled out of view.
//    ///  Required for all browser elements.
//    ///  Writable? No.
//    /// - Returns: A Array of AXUIElementRefs representing the columns of a browser. The columns will be grandchild elements of the browser, and will generally be of role kAXScrollArea.
//    public func visibleColumns() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVisibleColumnsAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func selectedColumns() -> [AXUIElement]? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSelectedColumnsAttribute,error: &error) as? [AXUIElement]
//    }
//    
//    public func sortDirection() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSortDirectionAttribute,error: &error)
//    }
//    
//    //MARK: row/column attributes
//    public func indexAttribute() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXIndexAttribute,error: &error)
//    }
//    
//    //MARK: outline attributes
//    public func disclosing() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDisclosingAttribute,error: &error)
//    }
//    
//    public func disclosedRows() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDisclosedRowsAttribute,error: &error)
//    }
//    
//    public func disclosedByRow() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDisclosedByRowAttribute,error: &error)
//    }
//    
//    public func disclosureLevel() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXDisclosureLevelAttribute,error: &error)
//    }
//    
//    //MARK: matte attributes
//    public func matteHole() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMatteHoleAttribute,error: &error)
//    }
//    
//   
//    public func matteContentUIElement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMatteContentUIElementAttribute,error: &error)
//    }
//    
//    //MARK: ruler attributes
//    public func markerUIElements() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMarkerUIElementsAttribute,error: &error)
//    }
//    
//    public func units() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXUnitsAttribute,error: &error)
//    }
//    
//    public func unitDescription() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXUnitDescriptionAttribute,error: &error)
//    }
//    
//    public func markerType() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMarkerTypeAttribute,error: &error)
//    }
//    
//    public func markerTypeDescription() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXMarkerTypeDescriptionAttribute,error: &error)
//    }
//    
//    //MARK: Dock attributes
//    public func isApplicationRunning() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXIsApplicationRunningAttribute,error: &error)
//    }
//    
//    //MARK: search field attributes
//    public func searchButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXSearchButtonAttribute,error: &error)
//    }
//    
//    public func clearButton() -> AXUIElement? {
//        var error : AXError = AXError.failure
//        return self.valueOfAXUIElement(attributeKey: kAXClearButtonAttribute,error: &error)
//    }
//    
//    
//    //MARK: grid attributes
//    public func rowCount() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRowCountAttribute,error: &error)
//    }
//    
//    public func columnCount() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnCountAttribute,error: &error)
//    }
//    
//    public func orderedByRow() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXOrderedByRowAttribute,error: &error)
//    }
//    
//    //MARK: level indicator attributes
//    public func warningValue() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXWarningValueAttribute,error: &error)
//    }
//    
//    public func criticalValue() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXCriticalValueAttribute,error: &error)
//    }
//    
//    //MARK: cell-based table attributes
//    public func selectedCells() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXSelectedCellsAttribute,error: &error)
//    }
//    
//    public func visibleCells() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVisibleCellsAttribute,error: &error)
//    }
//    
//    public func rowHeaderUIElement() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRowHeaderUIElementsAttribute,error: &error)
//    }
//    
//    public func columnHeaderUIElements() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnHeaderUIElementsAttribute,error: &error)
//    }
//    
//    //MARK: cell attributes
//    public func rowIndexRange() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRowIndexRangeAttribute,error: &error)
//    }
//    public func columnIndexRange() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnIndexRangeAttribute,error: &error)
//    }
//    
//    //MARK: layout area attributes
//    public func horizontalUnits() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHorizontalUnitsAttribute,error: &error)
//    }
//    
//    public func verticalUnits() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVerticalUnitsAttribute,error: &error)
//    }
//    
//    public func horizontalUnitDescription() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHorizontalUnitDescriptionAttribute,error: &error)
//    }
//    
//    public func verticalUnitDescription() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVerticalUnitDescriptionAttribute,error: &error)
//    }
//    
//    public func handles() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXHandlesAttribute,error: &error)
//    }
//    
//    //MARK: obsolete/unknown attributes
//    public func text() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXTextAttribute,error: &error)
//    }
//    
//    public func visibleText() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXVisibleTextAttribute,error: &error)
//    }
//    
//    public func isEditable() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXIsEditableAttribute,error: &error)
//    }
//    
//    public func columnTitles() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXColumnTitlesAttribute,error: &error)
//    }
//    
//    //MARK: obsolete/unknown attributes
//    public func identifier() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXIdentifierAttribute,error: &error)
//    }
//    
//    //MARK: UI element identification attributes
//    public func alternateUIVisible() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXAlternateUIVisibleAttribute,error: &error)
//    }
//    
//    //MARK: Text Suite Parameterized Attributes
//    public func lineForIndexParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLineForIndexParameterizedAttribute,error: &error)
//    }
//    
//    public func rangeForLineParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRangeForLineParameterizedAttribute,error: &error)
//    }
//    
//    public func stringForRangeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXStringForRangeParameterizedAttribute,error: &error)
//    }
//    
//    public func rangeForPositionParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRangeForPositionParameterizedAttribute,error: &error)
//    }
//    
//    public func rangeForIndexParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRangeForIndexParameterizedAttribute,error: &error)
//    }
//    
//    public func boundsForRangeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXBoundsForRangeParameterizedAttribute,error: &error)
//    }
//    
//    public func RTFForRangeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXRTFForRangeParameterizedAttribute,error: &error)
//    }
//    
//    public func attributedStringForRangeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXAttributedStringForRangeParameterizedAttribute,error: &error)
//    }
//    
//    public func styleRangeForIndexParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXStyleRangeForIndexParameterizedAttribute,error: &error)
//    }
//    
//    //MARK: cell-based table parameterized attributes
//    public func cellForColumnAndRowParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXCellForColumnAndRowParameterizedAttribute,error: &error)
//    }
//    
//    //MARK: layout area parameterized attributes
//    public func layoutPointForScreenPointParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLayoutPointForScreenPointParameterizedAttribute,error: &error)
//    }
//    
//    public func layoutSizeForScreenSizeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXLayoutSizeForScreenSizeParameterizedAttribute,error: &error)
//    }
//    
//    public func screenPointForLayoutPointParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXScreenPointForLayoutPointParameterizedAttribute,error: &error)
//    }
//    
//    public func screenSizeForLayoutSizeParameterized() -> Any? {
//        var error : AXError = AXError.failure
//        return self.value(attributeKey: kAXScreenSizeForLayoutSizeParameterizedAttribute,error: &error)
//    }
//}
