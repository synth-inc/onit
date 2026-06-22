//
//  String+KeyCode.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import Carbon

extension String {
    
    /**
     Retrieve the `CGKeyCode` from a key regardless of the keyboard layout.
     */
    var keyCode: CGKeyCode? {
        guard count == 1, let firstChar = unicodeScalars.first else {
            return nil
        }
        
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutDataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        
        let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
        let keyLayoutPtr = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
        
        for keyCode in 0...127 {
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length = 0
            
            let error = UCKeyTranslate(
                keyLayoutPtr,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                4,
                &length,
                &chars
            )
            
            if error == noErr, length > 0 {
                let keyChar = String(utf16CodeUnits: chars, count: Int(length))
                if let keyFirstChar = keyChar.unicodeScalars.first, keyFirstChar == firstChar {
                    return CGKeyCode(keyCode)
                }
            }
        }
        
        return nil
    }
}
