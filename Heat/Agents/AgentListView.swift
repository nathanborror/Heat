import SwiftUI
import HeatKit

struct AgentListView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                Button(action: { router.navigate(to: .agentForm(nil)) }) {
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
                            model: store.get(modelID: agent.modelID),
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
                Button("Done", action: { dismiss() })
            }
        }
    }
    
    func handleSelection(_ agent: Agent) {
        let chat = store.createChat(agentID: agent.id)
        Task { await store.upsert(chat: chat) }
        dismiss()
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
    let model: Model?
    let height: CGFloat
    let selection: AgentCallback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { selection(agent) }) {
                ZStack(alignment: .topTrailing) {
                    AgentTilePicture(picture: agent.picture, height: height, cornerRadius: 12)
                    if let model = model, let family = model.family {
                        Text(family)
                            .font(.footnote)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .foregroundStyle(.regularMaterial)
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 4))
                            .padding(8)
                    }
                }
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

#Preview {
    let store = Store.shared
    store.resetAll()
    
    return NavigationStack {
        AgentListView()
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Text("Done")
                    }
                }
            }
    }.environment(store)
}
