import SwiftUI
import HeatKit

struct FileRow: View {
    @Environment(AppState.self) var state

    let tree: FileTree
    let depth: Int

    var body: some View {
        if let file = try? API.shared.file(tree.id) {
            HStack {
                Text(file.name ?? file.path)

                Spacer()

                if let count = tree.children?.count, count > 0 {
                    Text("\(count) items")
                        .foregroundStyle(.tertiary)
                }
                if file.flag == "pin" {
                    Image(systemName: "flag.fill")
                        .imageScale(.small)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
