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

extension Int64 {

    var toSizeString: String {
        let KB: Double = 1024
        let MB = KB * 1024
        let GB = MB * 1024
        let TB = GB * 1024
        let PB = TB * 1024
        let EB = PB * 1024
        
        let bytes = Double(self)
        
        if bytes < KB {
            return "\(self) Bytes"
        } else if bytes < MB {
            return String(format: "%.2f KB", Double(self) / KB)
        } else if bytes < GB {
            return String(format: "%.2f MB", Double(self) / MB)
        } else if bytes < TB {
            return String(format: "%.2f GB", Double(self) / GB)
        } else if bytes < PB {
            return String(format: "%.2f TB", Double(self) / TB)
        } else if bytes < EB {
            return String(format: "%.2f PB", Double(self) / PB)
        } else {
            return String(format: "%.2f EB", Double(self) / EB)
        }
    }
}
