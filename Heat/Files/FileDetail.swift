import SwiftUI
import HeatKit

struct FileDetail: View {
    @Environment(AppState.self) var state

    let fileID: String?

    var body: some View {
        if let fileID, let file = try? API.shared.file(fileID) {
            if file.isDirectory {
                ContentUnavailableView {
                    Label(file.name ?? "Untitled folder", systemImage: "folder")
                }
            }
            if file.isConversation {
                ConversationView(file: file)
                    .id(file.id)
            }
            if file.isDocument {
               DocumentView(file: file)
                    .id(file.id)
            }
        }
    }
}
