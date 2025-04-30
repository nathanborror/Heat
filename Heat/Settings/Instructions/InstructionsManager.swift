import Foundation
import Observation
import GenKit
import HeatKit

@Observable
@MainActor
class InstructionsManager {

    var instructions: [File]

    init(instructions: [File]) {
        self.instructions = instructions
    }

    func get(_ instructionID: String?) -> File? {
        instructions.first(where: { $0.id == instructionID })
    }
}
