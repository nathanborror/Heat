import SwiftUI
import HeatKit

struct AgentListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
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
    private let heightDivisor: CGFloat = 2.5
    #endif
}

struct AgentTile: View {
    @Environment(\.colorScheme) var colorScheme
    
    typealias AgentCallback = (Agent) -> Void
    
    let agent: Agent
    let height: CGFloat
    let selection: AgentCallback
    
    var body: some View {
        Button(action: { selection(agent) }) {
            VStack(spacing: 0) {
                PictureView(picture: agent.picture)
                    .frame(height: height)
                    .clipped()
                VStack {
                    HStack {
                        Spacer()
                        Text(agent.name)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(2)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .frame(minHeight: 34)
                }
                .padding(.vertical, 12)
                .background(.thinMaterial)
                .background {
                    PictureView(picture: agent.picture)
                        .clipped()
                }
            }
        }
        .tint(.primary)
        .buttonStyle(.borderless)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        AgentListView()
    }.environment(Store.preview)
}
