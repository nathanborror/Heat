import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PictureView: View {
    let asset: Asset

    var scale: Double = 1.0
    var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            switch asset.kind {
            case .image:
                switch asset.location {
                case .filesystem, .cache, .url:
                    if let url = asset.url {
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
                    } else {
                        empty(size: geo.size)
                    }
                case .bundle:
                    Image(asset.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale, anchor: .top)
                        .offset(offset)
                case .none:
                    if let data = asset.data {
                        #if os(macOS)
                        if let image = NSImage(data: data) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            Rectangle()
                                .fill(.secondary)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                        #else
                        if let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            Rectangle()
                                .fill(.secondary)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                        #endif
                    } else {
                        empty(size: geo.size)
                    }
                }

            case .video:
                VideoView(name: asset.name)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale, anchor: .top)
                    .offset(offset)

            case .audio:
                empty(size: geo.size)

            case .symbol:
                ZStack {
                    Image(systemName: asset.name)
                        .resizable()
                        .foregroundStyle(.white)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width/2.5, height: geo.size.width/2.5)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(asset.backgroundColor ?? .secondary)
            }
        }
    }

    func empty(size: CGSize) -> some View {
        Rectangle()
            .fill(asset.backgroundColor ?? .secondary)
            .frame(width: size.width, height: size.height)
    }
}
