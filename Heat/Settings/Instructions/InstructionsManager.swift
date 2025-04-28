import Foundation
import Observation
import GenKit
import HeatKit

@Observable
@MainActor
class InstructionsManager {

    var instructions: [Instruction]

    init(instructions: [Instruction]) {
        self.instructions = instructions
    }

    func get(_ instructionID: String?) -> Instruction? {
        instructions.first(where: { $0.id == instructionID })
    }

    func update(_ instruction: Instruction) {
        guard let index = instructions.firstIndex(where: { $0.id == instruction.id }) else { return }
        instructions[index] = instruction
        save()
    }

    func save() {
    }
}
