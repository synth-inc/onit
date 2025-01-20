//
//  AccessibilityParserConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 16/01/2025.
//

import ApplicationServices.HIServices.AXAttributeConstants

struct AccessibilityParserConfig {
    
    /**
     * Accessibility's attributes to read
     *
     * See Apple documentation on attributes :
     * https://developer.apple.com/documentation/applicationservices/carbon_accessibility/attributes
     *
     */
    static let attributes: [String] = [
        kAXRoleAttribute,
        kAXSubroleAttribute,
        kAXRoleDescriptionAttribute,
        kAXHelpAttribute,
        kAXTitleAttribute,
        kAXValueAttribute,
//            kAXMinValueAttribute,
//            kAXMaxValueAttribute,
//            kAXEnabledAttribute,
//        kAXFocusedAttribute,
//            kAXSelectedChildrenAttribute,
//            kAXVisibleChildrenAttribute,
//            kAXWindowAttribute,
//            kAXTopLevelUIElementAttribute,
//            kAXPositionAttribute,
//            kAXSizeAttribute,
        kAXOrientationAttribute,
        kAXDescriptionAttribute,
        kAXSelectedTextAttribute,
        kAXSelectedTextRangeAttribute,
        kAXNumberOfCharactersAttribute,
        kAXVisibleCharacterRangeAttribute,
        kAXSharedTextUIElementsAttribute,
        kAXSharedCharacterRangeAttribute,
        kAXInsertionPointLineNumberAttribute,
        kAXMainAttribute,
        kAXMinimizedAttribute,
//            kAXCloseButtonAttribute,
//            kAXZoomButtonAttribute,
//            kAXMinimizeButtonAttribute,
//            kAXToolbarButtonAttribute,
        kAXGrowAreaAttribute,
        kAXProxyAttribute,
        kAXTitleUIElementAttribute,
        kAXServesAsTitleForUIElementsAttribute,
        kAXLinkedUIElementsAttribute,
//            kAXContentsAttribute,      <-- do some research in it
        kAXLabelUIElementsAttribute,
//            kAXIncrementButtonAttribute,
//            kAXDecrementButtonAttribute,
        kAXFilenameAttribute,
//            kAXExpandedAttribute,
//            kAXSelectedAttribute,
//            kAXSplittersAttribute,
//            kAXNextContentsAttribute,  <-- do some research in it
        kAXDocumentAttribute,
        kAXURLAttribute,
        kAXIndexAttribute,
        kAXRowCountAttribute,
        kAXColumnCountAttribute,
        kAXOrderedByRowAttribute,
        kAXHorizontalScrollBarAttribute,
        kAXVerticalScrollBarAttribute,
//            kAXOverflowButtonAttribute,
        kAXSortDirectionAttribute,
//            kAXSelectedCellsAttribute,
//            kAXVisibleCellsAttribute,
        kAXRowHeaderUIElementsAttribute,
        kAXColumnHeaderUIElementsAttribute,
        kAXRowIndexRangeAttribute,
        kAXColumnIndexRangeAttribute,
//            kAXDisclosureLevelAttribute,
//            kAXSearchButtonAttribute,
//            kAXClearButtonAttribute,
        kAXMenuItemMarkCharAttribute,
        kAXMenuItemCmdCharAttribute,
        kAXMenuItemCmdVirtualKeyAttribute,
        kAXMenuItemCmdGlyphAttribute,
        kAXMenuItemCmdModifiersAttribute,
        kAXPlaceholderValueAttribute,
//            kAXAlternateUIVisibleAttribute,
        kAXFocusedUIElementAttribute
    ]
    
    /**
     
     */
    static let recursiveDepthMax = 1000
}
