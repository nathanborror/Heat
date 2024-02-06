#if os(iOS)
import UIKit

extension UIImage {
    
    func resize(to targetSize: CGSize) -> Data? {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)
        let scaledImage = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
        return scaledImage.pngData()
    }
}
#endif
