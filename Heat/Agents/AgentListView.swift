import SwiftUI
import HeatKit

struct AgentListView: View {
    @Environment(Store.self) private var store
    
    @State var router: MainRouter
    
    var body: some View {
        RoutingView(router: router) {
            GeometryReader { proxy in
                ScrollView {
                    Button(action: { router.presentAgentForm(nil) }) {
                        HStack {
                            Spacer()
                            Text("Create Agent")
                            Spacer()
                        }
                        .padding()
                    }
                    .background(.tint.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.agents) { agent in
                            AgentTile(
                                agent: agent,
                                height: proxy.size.width/heightDivisor,
                                selection: handleSelection
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Agents")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { router.dismiss() })
                }
            }
        }
    }
    
    func handleSelection(_ agent: Agent) {
        router.presentingModelPicker(agent)
    }
    
    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let heightDivisor: CGFloat = 3
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let heightDivisor: CGFloat = 2
    #endif
}

struct AgentTile: View {
    @Environment(\.colorScheme) var colorScheme
    
    typealias AgentCallback = (Agent) -> Void
    
    let agent: Agent
    let height: CGFloat
    let selection: AgentCallback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { selection(agent) }) {
                AgentTilePicture(picture: agent.picture, height: height, cornerRadius: 12)
            }
            .frame(height: height)
            .buttonStyle(.borderless)
            
            AgentTileText(title: agent.name, subtitle: agent.tagline)
        }
    }
}

struct AgentTilePicture: View {
    let picture: Media
    let height: CGFloat
    let cornerRadius: Double
    
    var body: some View {
        PictureView(picture: picture)
            .frame(height: height)
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .tint(.primary.opacity(0.1))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            }
    }
}

struct AgentTileText: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
