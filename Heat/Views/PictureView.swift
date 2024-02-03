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
            if let data = asset.data, asset.kind != .audio {
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
            }
            
            switch asset.kind {
            case .image:
                switch asset.location {
                case .filesystem, .cache, .url:
                    if let url = asset.url {
                        AsyncImage(url: url, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }, placeholder: {
                            Rectangle()
                                .frame(width: geo.size.width, height: geo.size.height)
                        })
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
                    empty(size: geo.size)
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

#Preview {
    PictureView(asset: .init(name: "plus", kind: .symbol, location: .none))
        .frame(width: 64, height: 64)
        .clipShape(Squircle())
}
