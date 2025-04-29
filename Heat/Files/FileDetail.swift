import SwiftUI
import HeatKit

struct FileDetail: View {
    @Environment(AppState.self) var state

    let fileID: String?

    var body: some View {
        if let fileID, let file = try? API.shared.file(fileID) {
            if file.isDirectory {
                ContentUnavailableView(file.name ?? "Untitled Folder", systemImage: "folder")
            }
            if file.isConversation {
                ConversationView(fileID: fileID)
                    .id(fileID)
            }
            if file.isDocument {
               DocumentView(fileID: fileID)
                    .id(fileID)
            }
        }
    }
}
