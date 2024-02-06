#if os(macOS)
import AppKit

extension NSImage {
    
    func pngData() -> Data? {
        guard let tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    func resize(to targetSize: CGSize) -> Data? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let scaledImage = NSImage(size: scaledImageSize)
        
        scaledImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        draw(in: CGRect(origin: .zero, size: scaledImageSize),
                   from: CGRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        scaledImage.unlockFocus()

        guard let cgImage = scaledImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }
}
#endif
