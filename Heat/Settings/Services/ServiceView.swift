import SwiftUI
import GenKit
import HeatKit

struct ServicesView: View {
    @Environment(AppState.self) var state

    @State var selection: String?
    @State var manager: ServicesManager = .init()

    var body: some View {
        #if os(macOS)
        HSplitView {
            List(selection: $selection) {
                ForEach(manager.services) { service in
                    Text(service.name).tag(service.id)
                }
            }
            .frame(minWidth: 200, idealWidth: 200, maxWidth: 400)
            .listStyle(.bordered)
            .alternatingRowBackgrounds(.enabled)
            .environment(\.defaultMinListRowHeight, 32)
            .overlay(alignment: .bottom) {
                Button {
                    selection = nil
                } label: {
                    HStack {
                        Text("Defaults")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(.linearGradient(colors: [Color(hex: "#FAFAFA"), Color(hex: "#F5F5F5")], startPoint: .top, endPoint: .bottom))
                    .padding(1)
                }
                .buttonStyle(.plain)
                .overlay {
                    Rectangle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                }
            }

            Group {
                if let service = manager.get(selection) {
                    ServiceForm(service: service)
                        .id(service.id)
                } else {
                    Form {
                        ServiceDefaults()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .layoutPriority(1)
        }
        .onAppear {
            manager.update(config: state.config)
        }
        .onDisappear {
            manager.save()
        }
        .environment(manager)
        #else
        List {
            ServiceDefaults()

            Section("Services") {
                ForEach(manager.services) { service in
                    NavigationLink(service.name) {
                        ServiceForm(service: service)
                            .id(service.id)
                            .environment(manager)
                    }
                }
            }
        }
        .navigationTitle("Service")
        .navigationBarTitleDisplayMode(.inline)
        .environment(manager)
        .onAppear {
            manager.update(config: state.config)
        }
        .onDisappear {
            manager.save()
        }
        #endif
    }
}
