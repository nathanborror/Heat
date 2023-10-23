import SwiftUI
import HeatKit

struct AgentListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
    @State private var isShowingForm = false
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                Button(action: { isShowingForm.toggle() }) {
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
                        AgentTile(agent: agent, height: proxy.size.width/heightDivisor, selection: handleSelection)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingForm) {
            NavigationStack {
                AgentForm()
            }.environment(store)
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

#Preview {
    NavigationStack {
        AgentListView()
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Text("Done")
                    }
                }
            }
    }.environment(Store.shared)
}
