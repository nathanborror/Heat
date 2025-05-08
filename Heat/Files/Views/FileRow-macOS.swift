import SwiftUI
import HeatKit

struct FileRow: View {
    @Environment(AppState.self) var state

    let tree: FileTree
    let depth: Int

    @State private var isDropping = false

    var body: some View {
        if let file = try? API.shared.file(tree.id) {
            HStack(spacing: 4) {
                Spacer(minLength: 0)
                    .frame(width: leadingSpace(file))

                if file.isDirectory {
                    disclosureButton(file)
                }

                Text(file.name ?? "Untitled")

                if file.isDirectory, let count = tree.children?.count, count > 0 {
                    Text("\(count) items")
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }

                Spacer()

                if file.flag == "pin" {
                    Image(systemName: "flag.fill")
                        .imageScale(.small)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isDropping ? .blue : .clear)

            // Child references
            if file.isExpanded, let children = tree.children {
                ForEach(children) { child in
                    FileRow(tree: child, depth: depth+1)
                        .tag(child.id)
                }
            }
        }
    }

    func disclosureButton(_ file: File) -> some View {
        Button(action: handleExpandFolder) {
            Image(systemName: file.isExpanded ? "chevron.down" : "chevron.right")
                .imageScale(.small)
                .fontWeight(.medium)
        }
        .buttonStyle(.borderless)
        .frame(width: 8)
    }

    func leadingSpace(_ file: File) -> CGFloat {
        if file.isDirectory {
            return CGFloat(depth * 18)
        } else {
            return CGFloat(depth * 18) + 8 + 4
        }
    }

    func handleExpandFolder() {
        Task {
            do {
                var file = try API.shared.file(tree.id)
                file.isExpanded.toggle()
                try await API.shared.fileUpdate(file)
            } catch {
                print(error)
            }
        }
    }
}
