import Foundation

struct WindowFrame: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    
    init(from rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.width
        self.height = rect.height
    }
    
    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
    
    static func fromScreenToWindow(_ screenFrame: CGRect) -> WindowFrame {
        // Convert from screen coordinates (top-left origin) to window coordinates (bottom-left origin)
        guard let screen = NSScreen.main else {
            return WindowFrame(from: screenFrame)
        }
        
        let screenHeight = screen.frame.height
        let windowY = screenHeight - screenFrame.maxY
        
        return WindowFrame(
            x: screenFrame.minX,
            y: windowY,
            width: screenFrame.width,
            height: screenFrame.height
        )
    }
    
    func toScreenCoordinates() -> CGRect {
        // Convert from window coordinates (bottom-left origin) to screen coordinates (top-left origin)
        guard let screen = NSScreen.main else {
            return self.rect
        }
        
        let screenHeight = screen.frame.height
        let screenY = screenHeight - (y + height)
        
        return CGRect(
            x: x,
            y: screenY,
            width: width,
            height: height
        )
    }
}