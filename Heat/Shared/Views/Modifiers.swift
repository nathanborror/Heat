import SwiftUI

struct AppFormStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 400, height: 500)
            #endif
    }
}

extension View {

    func appFormStyle() -> some View {
        self.modifier(AppFormStyle())
    }
}
