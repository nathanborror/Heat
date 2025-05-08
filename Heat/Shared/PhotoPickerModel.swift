import SwiftUI
import OSLog
import SharedKit
import PhotosUI

private let logger = Logger(subsystem: "ImagePicker", category: "App")

@MainActor @Observable
final class PhotoPickerModel {

    struct Selection: Identifiable {
        var id: String
        var state: State
        #if os(macOS)
        var photo: NSImage?
        #else
        var photo: UIImage?
        #endif

        enum State {
            case empty
            case loading(Progress)
            case success
            case failure(PhotoPickerError)
        }
    }

    var selections: [Selection] = []
    var items: [PhotosPickerItem] = [] {
        didSet { handleSelectionChange() }
    }

    func writeAll() throws -> [String] {
        var out = [String]()
        for selected in selections {
            guard let image = selected.photo else {
                throw PhotoPickerError.missingPhoto
            }
            guard let data = image.pngData() else {
                throw PhotoPickerError.missingPhoto
            }
            let filename = "\(selected.id).png"
            let resource = Resource.document(filename)

            guard let url = resource.url else {
                throw PhotoPickerError.missingResourceURL
            }
            try data.write(to: url)
            out.append(filename)
        }
        return out
    }

    func remove(id: String) {
        selections.removeAll { $0.id == id }
        items.removeAll { $0.itemIdentifier == id }
    }

    func removeAll() {
        selections.removeAll()
        items.removeAll()
    }

    // MARK: - Private

    private func handleSelectionChange() {
        for item in items {
            if let id = item.itemIdentifier, let progress = handleLoadTransferable(from: item) {
                let image = Selection(id: id, state: .loading(progress))
                upsert(image: image)
            }
        }
    }

    private func handleLoadTransferable(from item: PhotosPickerItem) -> Progress? {
        guard let id = item.itemIdentifier else { return nil }
        return item.loadTransferable(type: PhotoTransfer.self) { result in
            switch result {
            case .success(let image?):
                let image = Selection(id: id, state: .success, photo: image.image)
                self.upsert(image: image)
            case .success(nil):
                let image = Selection(id: id, state: .empty)
                self.upsert(image: image)
            case .failure:
                let image = Selection(id: id, state: .failure(.transferFailed))
                self.upsert(image: image)
            }
        }
    }

    private func upsert(image: Selection) {
        if let index = selections.firstIndex(where: { $0.id == image.id }) {
            selections[index] = image
        } else {
            selections.append(image)
        }
    }
}

enum PhotoPickerError: LocalizedError {
    case missingPhoto
    case missingResourceURL
    case transferFailed
    case transferInProgress

    var errorDescription: String? {
        switch self {
        case .missingPhoto: "Missing photo"
        case .missingResourceURL: "Missing resource URL"
        case .transferFailed: "Image transfer failed"
        case .transferInProgress: "Image transfer in progress"
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .missingPhoto: "Try picking an image again."
        case .missingResourceURL: "Try picking an image again."
        case .transferFailed: "Try again"
        case .transferInProgress: "Wait for transfer to complete."
        }
    }
}

struct PhotoTransfer: Transferable {
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
            return PhotoTransfer(image: image)
            #else
            guard let image = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return PhotoTransfer(image: image)
            #endif
        }
    }
}
