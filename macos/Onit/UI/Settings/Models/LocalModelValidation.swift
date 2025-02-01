import Foundation

struct LocalModelValidation {
    static func validateKeepAlive(_ value: String) -> Bool {
        if value.isEmpty { return true }
        
        // Check for duration string format (e.g., "10m", "24h")
        let durationPattern = #"^-?\d+[mh]$"#
        if value.range(of: durationPattern, options: .regularExpression) != nil {
            return true
        }
        
        // Check for integer format
        if let intValue = Int(value) {
            return true // Any integer is valid (including negative and zero)
        }
        
        return false
    }
    
    static func validateFloat(_ value: String, min: Double? = nil, max: Double? = nil) -> Bool {
        if value.isEmpty { return true }
        
        guard let floatValue = Double(value) else { return false }
        
        if let min = min, floatValue < min { return false }
        if let max = max, floatValue > max { return false }
        
        return true
    }
    
    static func validateInt(_ value: String, min: Int? = nil, max: Int? = nil) -> Bool {
        if value.isEmpty { return true }
        
        guard let intValue = Int(value) else { return false }
        
        if let min = min, intValue < min { return false }
        if let max = max, intValue > max { return false }
        
        return true
    }
}