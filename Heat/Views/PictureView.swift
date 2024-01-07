import SwiftUI
import GenKit
import SharedKit

struct PictureView: View {
    let asset: Asset
        
    var body: some View {
        GeometryReader { geo in
            if asset.kind == .image {
                switch asset.location {
                case .filesystem, .cache, .url:
                    AsyncImage(url: asset.url, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }, placeholder: {
                        Rectangle()
                            .frame(width: geo.size.width, height: geo.size.height)
                    })
                case .bundle:
                    Image(asset.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                case .none:
                    ZStack {
                        Image("sparkle")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width/2, height: geo.size.width/2)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .background(asset.backgroundColor ?? .secondary)
                }
            }
            
            if asset.kind == .symbol {
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
}

struct Squircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        
        path.move(to: CGPoint(x: 0.5*width, y: height))
        path.addCurve(to: CGPoint(x: width, y: 0.5*height), control1: CGPoint(x: 0.919*width, y: height), control2: CGPoint(x: width, y: 0.919*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0), control1: CGPoint(x: width, y: 0.081*height), control2: CGPoint(x: 0.919*width, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: 0.5*height), control1: CGPoint(x: 0.081*width, y: 0), control2: CGPoint(x: 0, y: 0.081*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: height), control1: CGPoint(x: 0, y: 0.919*height), control2: CGPoint(x: 0.081*width, y: height))
        path.closeSubpath()
        
        return path
    }
}

extension Asset {
    
    var backgroundColor: Color? {
        guard let hex = background else { return nil }
        return Color(hex: hex)
    }
}
