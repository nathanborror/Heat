import SwiftUI

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
