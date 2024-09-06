import SwiftUI

struct AppFormStyle: ViewModifier {
        
    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 400)
            .frame(minHeight: 450)
            #endif
    }
}

extension View {
    
    func appFormStyle() -> some View {
        self.modifier(AppFormStyle())
    }
}
