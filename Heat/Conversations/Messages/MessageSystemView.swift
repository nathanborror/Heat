import SwiftUI
import GenKit

struct MessageSystemView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(message.kind == .error ? "System Error" : "System Message")
                .foregroundStyle(.secondary)
            Text(message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                .foregroundStyle(message.kind == .error ? .red : .secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.subheadline)
        .padding(.vertical, 2)
    }
}
