import SwiftUI
import HeatKit

class MainRouter: Router {
    
    func presentChats() {
        presentSheet(.chats)
    }
    
    func presentChat(_ chatID: String) {
        navigateTo(.chat(chatID))
    }
    
    func presentChatInfo(_ chatID: String) {
        presentSheet(.chatInfo(chatID))
    }
    
    func presentAgents() {
        presentSheet(.agents)
    }
    
    func presentAgentForm(_ agent: Agent?) {
        navigateTo(.agentForm(agent))
    }
    
    func presentingModelPicker(_ agent: Agent) {
        navigateTo(.modelPicker(agent))
    }
    
    func presentingModel(_ modelID: String) {
        navigateTo(.model(modelID))
    }
    
    func presentPreferences() {
        presentSheet(.preferences)
    }
    
    func presentNewChat(_ chatID: String) {
        dismiss()
        navigateTo(.chat(chatID))
    }
    
    override func view(spec: ViewSpec, route: Router.Route) -> AnyView {
        AnyView(buildView(spec: spec, route: route))
    }
}

extension MainRouter {
    
    @ViewBuilder
    func buildView(spec: ViewSpec, route: Route) -> some View {
        switch spec {
        case .chats:
            ChatListView(router: router(route: route))
        case .chat(let chatID):
            ChatView(chatID: chatID, router: router(route: route))
        case .chatInfo(let chatID):
            ChatInfoView(chatID: chatID, router: router(route: route))
        case .agents:
            AgentListView(router: router(route: route))
        case .agentForm(let agent):
            AgentForm(agent: agent ?? .empty, router: router(route: route))
        case .modelPicker(let agent):
            ModelPickerView(agent: agent, router: router(route: route))
        case .model(let modelID):
            ModelView(modelID: modelID, router: router(route: route))
        case .preferences:
            PreferencesView(router: router(route: route))
        }
    }
    
    func router(route: Route) -> MainRouter {
        switch route {
        case .navigation:
            self
        case .sheet:
            MainRouter(isPresented: presentingSheet)
        case .fullScreenCover:
            MainRouter(isPresented: presentingFullScreen)
        case .modal:
            self
        }
    }
}
