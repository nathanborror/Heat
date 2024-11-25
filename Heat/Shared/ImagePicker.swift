import SwiftUI
import OSLog
import SharedKit
import PhotosUI

private let logger = Logger(subsystem: "ImagePicker", category: "App")

@MainActor @Observable
final class ImagePickerViewModel {

    struct SelectedImage: Identifiable {
        var id: String
        var state: State
        #if os(macOS)
        var image: NSImage?
        #else
        var image: UIImage?
        #endif

        enum State {
            case empty
            case loading(Progress)
            case success
            case failure(ImagePickerError)
        }
    }

    var imagesSelected: [SelectedImage] = []
    var imagesPicked: [PhotosPickerItem] = [] {
        didSet { handleSelectionChange() }
    }

    func writeAll() throws -> [String] {
        var out = [String]()
        for selected in imagesSelected {
            guard let image = selected.image else {
                throw ImagePickerError.missingImage
            }
            guard let data = image.pngData() else {
                throw ImagePickerError.missingImage
            }
            let filename = "\(selected.id).png"
            let resource = Resource.document(filename)

            guard let url = resource.url else {
                throw ImagePickerError.missingResourceURL
            }
            try data.write(to: url)
            out.append(filename)
        }
        return out
    }

    func remove(id: String) {
        imagesSelected.removeAll { $0.id == id }
        imagesPicked.removeAll { $0.itemIdentifier == id }
    }

    func removeAll() {
        imagesSelected.removeAll()
        imagesPicked.removeAll()
    }

    // MARK: - Private

    private func handleSelectionChange() {
        for item in imagesPicked {
            if let id = item.itemIdentifier, let progress = handleLoadTransferable(from: item) {
                let image = SelectedImage(id: id, state: .loading(progress))
                upsert(image: image)
            }
        }
    }

    private func handleLoadTransferable(from item: PhotosPickerItem) -> Progress? {
        guard let id = item.itemIdentifier else { return nil }
        return item.loadTransferable(type: ImageTransfer.self) { result in
            switch result {
            case .success(let image?):
                let image = SelectedImage(id: id, state: .success, image: image.image)
                self.upsert(image: image)
            case .success(nil):
                let image = SelectedImage(id: id, state: .empty)
                self.upsert(image: image)
            case .failure:
                let image = SelectedImage(id: id, state: .failure(.transferFailed))
                self.upsert(image: image)
            }
        }
    }

    private func upsert(image: SelectedImage) {
        if let index = imagesSelected.firstIndex(where: { $0.id == image.id }) {
            imagesSelected[index] = image
        } else {
            imagesSelected.append(image)
        }
    }
}

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
            #if os(macOS)
            guard let image = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImageTransfer(image: image)
            #else
            guard let image = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return ImageTransfer(image: image)
            #endif
        }
    }
}
