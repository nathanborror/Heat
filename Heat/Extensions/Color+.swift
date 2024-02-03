import SwiftUI

extension Color {
    
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    init(hex str: String, alpha: Double = 1.0) {
        var str = str
        
        // Remove the leading "#" if present
        if str.hasPrefix("#") {
            str.remove(at: str.startIndex)
        }
        
        // Attempt to parse the hex string
        var hexInt: UInt64 = 0
        Scanner(string: str).scanHexInt64(&hexInt)
        
        self.init(hex: UInt(hexInt), alpha: alpha)
    }
}
