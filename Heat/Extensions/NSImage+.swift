#if os(macOS)
import AppKit

extension NSImage {
    
    func pngData() -> Data? {
        guard let tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
#endif
