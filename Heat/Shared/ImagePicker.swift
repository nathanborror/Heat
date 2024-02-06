import SwiftUI
import OSLog
import SharedKit
import PhotosUI

private let logger = Logger(subsystem: "ImagePicker", category: "Heat")

enum ImagePickerError: LocalizedError {
    case missingImage
    case missingResourceURL
    case transferFailed
    case transferInProgress
    
    var errorDescription: String? {
        switch self {
        case .missingImage: "Missing image"
        case .missingResourceURL: "Missing resource URL"
        case .transferFailed: "Image transfer failed"
        case .transferInProgress: "Image transfer in progress"
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .missingImage: "Try picking an image again."
        case .missingResourceURL: "Try picking an image again."
        case .transferFailed: "Try again"
        case .transferInProgress: "Wait for transfer to complete."
        }
    }
}

@Observable
final class ImagePickerViewModel {
    
    enum ImageState {
        case empty
        case loading(Progress)
        #if os(macOS)
        case success(NSImage)
        #else
        case success(UIImage)
        #endif
        case failure(ImagePickerError)
    }
    
    var imageState: ImageState = .empty
    
    var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = handleLoadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    
    var data: Data? {
        guard case .success(let image) = imageState else { return nil }
        return image.pngData()
    }
    
    var megabytes: Double {
        guard let data else { return 0 }
        return Double(data.count) / Double(1024 * 1024)
    }
    
    #if os(macOS)
    var image: NSImage? {
        guard let data else { return nil }
        return NSImage(data: data)
    }
    #else
    var image: UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
    #endif
    
    func write() throws -> String {
        guard let data else {
            throw ImagePickerError.missingImage
        }
        let filename = "\(String.id).png"
        let resource = Resource.document(filename)
        
        guard let url = resource.url else {
            throw ImagePickerError.missingResourceURL
        }
        try data.write(to: url)
        return filename
    }
    
    private func handleLoadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ImageTransfer.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let image?):
                    self.imageState = .success(image.image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(.transferFailed)
                    logger.error("image transfer failed: \(error)")
                }
            }
        }
    }
}

struct ImageTransfer: Transferable {
    #if os(macOS)
    let image: NSImage
    #else
    let image: UIImage
    #endif

    enum TransferError: Error {
        case importFailed
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            #if os(iOS)
            guard let image = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImageTransfer(image: image)
            #else
            guard let image = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImageTransfer(image: image)
            #endif
        }
    }
}
