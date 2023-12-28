import SwiftUI
import GenKit
import SharedKit

struct MediaView: View {
    let media: Media
        
    var body: some View {
        GeometryReader { geo in
            switch media {
            case .document(let mediaType):
                switch mediaType {
                case .image(let name):
                    AsyncImage(url: Resource.document(name).url!, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }, placeholder: {
                        Rectangle()
                            .frame(width: geo.size.width, height: geo.size.height)
                    })
                case .video(let name):
                    VideoView(name: name)
                        .frame(width: geo.size.width, height: geo.size.height)
                case .audio:
                    EmptyView()
                }
            case .bundle(let mediaType):
                switch mediaType {
                case .image(let name):
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                case .video(let name):
                    VideoView(name: name)
                        .frame(width: geo.size.width, height: geo.size.height)
                case .audio:
                    EmptyView()
                }

            case .color(let colorHexValue):
                ZStack {
                    Image("sparkle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width/2, height: geo.size.width/2)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color(hex: colorHexValue))

            case .data(let data):
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

            case .symbol(let symbolSystemName, let colorHexValue):
                ZStack {
                    Image(systemName: symbolSystemName)
                        .resizable()
                        .foregroundStyle(.white)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width/2.5, height: geo.size.width/2.5)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color(hex: colorHexValue))
                
            case .none:
                Rectangle()
                    .fill(.secondary)
                    .frame(width: geo.size.width, height: geo.size.height)
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
