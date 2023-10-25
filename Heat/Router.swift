import SwiftUI
import Observation

@Observable
final class Router {
    
    static var shared = Router()
    
    enum Destination: Codable, Hashable, Identifiable {
        case chat(String)
        case agentForm(String?)
        case agentList
        case preferences
        
        var id: String {
            switch self {
            case .chat(let chatID):         return "chat-\(chatID)"
            case .agentForm(let agentID):   return "agent-form-\(agentID ?? "new")"
            case .agentList:                return "agent-list"
            case .preferences:              return "preferences"
            }
        }
    }
    
    var active: Destination? = nil
    var presenting: Destination? = nil
    var path = NavigationPath() {
        didSet { pathDidSet() }
    }
    
    func navigate(to destination: Destination) {
        active = destination
        path.append(destination)
    }
    
    func present(_ destination: Destination) {
        active = destination
        presenting = destination
    }
    
    func navigateHome() {
        active = nil
        presenting = nil
        path.removeLast(path.count)
    }
    
    // Private
    
    private func pathDidSet() {
        guard path.count == 0 else { return }
        active = nil
    }
}
