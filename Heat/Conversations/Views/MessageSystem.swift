import SwiftUI
import GenKit
import HeatKit

struct MessageSystem: View {
    let message: Message
    
    var body: some View {
        Text(message.content ?? "None")
    }
}
