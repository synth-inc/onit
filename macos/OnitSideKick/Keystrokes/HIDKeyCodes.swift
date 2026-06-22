//
//  HIDKeyCodes.swift
//  Onit
//
//  Created by Timothy Lenardo on 8/27/25.
//

// MARK: - HID Key Codes Enum
enum HIDUsageIDs: UInt64, CaseIterable {
    // Letter Keys
    case a = 0x04
    case b = 0x05
    case c = 0x06
    case d = 0x07
    case e = 0x08
    case f = 0x09
    case g = 0x0A
    case h = 0x0B
    case i = 0x0C
    case j = 0x0D
    case k = 0x0E
    case l = 0x0F
    case m = 0x10
    case n = 0x11
    case o = 0x12
    case p = 0x13
    case q = 0x14
    case r = 0x15
    case s = 0x16
    case t = 0x17
    case u = 0x18
    case v = 0x19
    case w = 0x1A
    case x = 0x1B
    case y = 0x1C
    case z = 0x1D
    
    // Number Keys
    case one = 0x1E
    case two = 0x1F
    case three = 0x20
    case four = 0x21
    case five = 0x22
    case six = 0x23
    case seven = 0x24
    case eight = 0x25
    case nine = 0x26
    case zero = 0x27
    
    // Function Keys
    case f1 = 0x3A
    case f2 = 0x3B
    case f3 = 0x3C
    case f4 = 0x3D
    case f5 = 0x3E
    case f6 = 0x3F
    case f7 = 0x40
    case f8 = 0x41
    case f9 = 0x42
    case f10 = 0x43
    case f11 = 0x44
    case f12 = 0x45
    case f13 = 0x68
    case f14 = 0x69
    case f15 = 0x6A
    case f16 = 0x6B
    case f17 = 0x6C
    case f18 = 0x6D
    case f19 = 0x6E
    case f20 = 0x6F
    case f21 = 0x70
    case f22 = 0x71
    case f23 = 0x72
    case f24 = 0x73
    
    // Special Keys
    case returnKey = 0x28
    case escape = 0x29
    case backspace = 0x2A
    case tab = 0x2B
    case spacebar = 0x2C
    case minus = 0x2D
    case equals = 0x2E
    case leftBracket = 0x2F
    case rightBracket = 0x30
    case backslash = 0x31
    case nonUSHash = 0x32
    case semicolon = 0x33
    case quote = 0x34
    case graveAccent = 0x35
    case comma = 0x36
    case period = 0x37
    case forwardSlash = 0x38
    case capsLock = 0x39
    case insert = 0x49
    case home = 0x4A
    case pageUp = 0x4B
    case deleteForward = 0x4C
    case end = 0x4D
    case pageDown = 0x4E
    case rightArrow = 0x4F
    case leftArrow = 0x50
    case downArrow = 0x51
    case upArrow = 0x52
    case numLock = 0x53
    case printScreen = 0x46
    case scrollLock = 0x47
    case pause = 0x48
    case application = 0x65
    case power = 0x66
    case nonUSBackslash = 0x64
    
    // Keypad Keys
    case keypadSlash = 0x54
    case keypadAsterisk = 0x55
    case keypadMinus = 0x56
    case keypadPlus = 0x57
    case keypadEnter = 0x58
    case keypad1 = 0x59
    case keypad2 = 0x5A
    case keypad3 = 0x5B
    case keypad4 = 0x5C
    case keypad5 = 0x5D
    case keypad6 = 0x5E
    case keypad7 = 0x5F
    case keypad8 = 0x60
    case keypad9 = 0x61
    case keypad0 = 0x62
    case keypadPeriod = 0x63
    case keypadEquals = 0x67
    
    // Modifier Keys
    case leftControl = 0xE0
    case leftShift = 0xE1
    case leftAlt = 0xE2
    case leftGUI = 0xE3
    case rightControl = 0xE4
    case rightShift = 0xE5
    case rightAlt = 0xE6
    case rightGUI = 0xE7
    
    // Computed property to get the full HID usage code
    var hidUsageCode: UInt64 {
        return 0x700000000 | self.rawValue
    }
    
    // Convenience initializer from HID usage code
    init?(hidUsageCode: UInt64) {
        let rawValue = hidUsageCode & 0x000000FF
        guard let keyCode = HIDUsageIDs(rawValue: rawValue) else {
            return nil
        }
        self = keyCode
    }
}
