import SwiftUI
import HeatKit

struct PermissionList: View {
    @Environment(AppState.self) var state

    @Binding var selection: Permission?

    var body: some View {
        List(selection: $selection) {
            ForEach(Permission.allCases, id: \.self) { permission in
                Text(permission.description)
                    .tag(permission)
            }
        }
        .navigationTitle("Permissions")
    }
}
