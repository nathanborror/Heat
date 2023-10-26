import Foundation
import HeatKit

enum ViewSpec: Equatable, Hashable {
    
    case chats
    case chat(String)
    case chatInfo(String)
    case agents
    case agentForm(Agent?)
    case modelPicker(Agent)
    case model(String)
    case preferences
}

extension ViewSpec: Identifiable {
    
    var id: Self { self }
}
