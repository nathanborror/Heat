import SwiftUI
import HeatKit

struct AssistantPicker: View {
    @Environment(AppState.self) var state

    @State var showWelcomeSheet = false

    var body: some View {
        VStack {
            Menu {
                ForEach(state.agentsProvider.agents.filter { $0.kind == .assistant }) { agent in
                    Button(agent.name) {
                        Task {
                            var preferences = state.preferencesProvider.preferences
                            preferences.defaultAssistantID = agent.id
                            try await state.preferencesProvider.upsert(preferences)
                        }
                    }
                }
            } label: {
                HStack {
                    if let agentID = state.preferencesProvider.preferences.defaultAssistantID, let agent = try? state.agentsProvider.get(agentID) {
                        Text(agent.name)
                    } else {
                        Text("Pick assistant")
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.background)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .font(.subheadline)
        .buttonStyle(.plain)
        .sheet(isPresented: $showWelcomeSheet) {
            NavigationStack {
                ServiceOnboarding()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showWelcomeSheet = state.preferencesProvider.preferences.preferred.chatServiceID == nil
            }
        }
    }
}
