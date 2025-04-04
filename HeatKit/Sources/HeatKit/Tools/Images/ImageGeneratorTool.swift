import Foundation
import SharedKit
import GenKit

public struct ImageGeneratorTool {

    public struct Arguments: Codable {
        public var prompts: [String]
    }
    
    public static let function = Tool.Function(
        name: "generate_images",
        description: "Return thoughtful, detailed image prompts.",
        parameters: .init(
            type: .object,
            properties: [
                "prompts": .init(
                    type: .array,
                    description: "A list of detailed prompts describing images to generate.",
                    items: .init(type: .string, minItems: 1, maxItems: 9)
                ),
            ],
            required: ["prompts"]
        )
    )
}

extension ImageGeneratorTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension ImageGeneratorTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            
            let imageService = try await PreferencesProvider.shared.preferredImageService()
            let imageModel = try await PreferencesProvider.shared.preferredImageModel()
            
            // Generate image attachments
            var contents = [Message.Content]()
            for prompt in args.prompts {
                contents += try await makeImages(prompt: prompt, service: imageService, model: imageModel)
            }
            return [.init(
                role: .tool,
                contents: contents,
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": .string(args.prompts.count == 1 ? "Generating an image" : "Generating \(args.prompts.count) images")]
            )]
        } catch {
            return [.init(
                role: .tool,
                content: "Tool Failed: \(error.localizedDescription)",
                toolCallID: toolCall.id,
                name: toolCall.function.name
            )]
        }
    }
    
    private static func makeImages(prompt: String, service: ImageService, model: Model) async throws -> [Message.Content] {
        var out = [Message.Content]()
        try await ImageSession.shared.generate(service: service, model: model, prompt: prompt) { images in
            out = images.map { .image(data: $0, format: .jpeg) }
            out += [.text(prompt)]
        }
        return out
    }
}
