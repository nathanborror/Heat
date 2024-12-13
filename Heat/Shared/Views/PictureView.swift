import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PictureView: View {
    let url: URL?
    let data: Data?

    var scale: Double = 1.0
    var offset: CGSize = .zero

    init(url: URL? = nil, data: Data? = nil) {
        self.url = url
        self.data = data
    }

    var body: some View {
        GeometryReader { geo in
            if let url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                } placeholder: {
                    Rectangle()
                        .fill(.primary.opacity(0.05))
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            #if os(macOS)
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            #else
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            #endif
        }
    }
}
