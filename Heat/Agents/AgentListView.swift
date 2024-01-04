import SwiftUI
import HeatKit

struct AgentListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                NavigationLink(destination: { Text("Foo") }, label: { Text("Create Agent") })
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
                Button("Done", action: { dismiss() })
            }
        }
    }
    
    func handleSelection(_ agent: Agent) {
        print("not implemented")
    }
    
    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let heightDivisor: CGFloat = 3
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let heightDivisor: CGFloat = 3
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
            MediaView(media: agent.picture)
                .frame(height: height)
                .clipShape(.rect(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading) {
                Text(agent.name)
                    .font(.system(size: 13, weight: .medium))
                if let tagline = agent.tagline {
                    Text(tagline)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onTapGesture {
            selection(agent)
        }
    }
}

#Preview {
    NavigationStack {
        AgentListView()
    }.environment(Store.preview)
}
