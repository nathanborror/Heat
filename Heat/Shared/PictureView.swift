import SwiftUI
import HeatKit

struct PictureView: View {
    @Environment(Store.self) private var store
    
    var picture: Media
    
    @State var scale: Double = 1.0
    @State var offsetX: Double = 0.0
    @State var offsetY: Double = 0.0
    
    var body: some View {
        GeometryReader { geo in
            switch picture {
            case .bundle(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale, anchor: .top)
                    .offset(x: offsetX, y: offsetY)
            case .video(let name):
                VideoView(name: name)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale, anchor: .top)
                    .offset(x: offsetX, y: offsetY)
            case .filesystem(let name):
                AsyncImage(url: Filename.document(name).url!, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                }, placeholder: {
                    Rectangle()
                        .frame(width: geo.size.width, height: geo.size.height)
                })
            case .color(let hex):
                ZStack {
                    Image("sparkle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width/2, height: geo.size.width/2)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color(hex: hex))
            case .systemIcon(let systemName, let hex):
                ZStack {
                    Image(systemName: systemName)
                        .resizable()
                        .foregroundStyle(.white)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width/2.5, height: geo.size.width/2.5)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color(hex: hex))
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
