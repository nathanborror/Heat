import SwiftUI
import HeatKit

struct PermissionsView: View {
    @State var selection: Permission?

    var body: some View {
        #if os(macOS)
        HSplitView {
            PermissionList(selection: $selection)
                .frame(minWidth: 200, idealWidth: 200, maxWidth: 400)
                .listStyle(.bordered)
                .alternatingRowBackgrounds(.enabled)
                .environment(\.defaultMinListRowHeight, 32)

            Group {
                if let permission = selection {
                    PermissionForm(permission)
                } else {
                    VStack {
                        Spacer()
                        ContentUnavailableView("No Permission Selected", systemImage: "key.2.on.ring")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading)
            .layoutPriority(1)
        }
        #else
        NavigationStack {
            PermissionList(selection: $selection)
                .navigationTitle("Permission")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(item: $selection) { permission in
                    PermissionForm(permission)
                }
        }
        #endif
    }
}

enum Permission: CaseIterable, CustomStringConvertible {
    case notifications
    case location
    case music

    var description: String {
        switch self {
        case .notifications: "Notifications"
        case .location: "Location"
        case .music: "Music"
        }
    }
}
