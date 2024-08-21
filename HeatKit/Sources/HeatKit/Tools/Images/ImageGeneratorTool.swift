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
        parameters: JSONSchema(
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
            throw KitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension ImageGeneratorTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            
            let imageService = try await PreferencesStore.shared.preferredImageService()
            let imageModel = try await PreferencesStore.shared.preferredImageModel()
            
            // Generate image attachments
            var attachments = [Message.Attachment]()
            for prompt in args.prompts {
                if let attachment = try await makeImageAttachment(prompt: prompt, service: imageService, model: imageModel) {
                    attachments.append(attachment)
                }
            }
            return [.init(
                role: .tool,
                content: args.prompts.joined(separator: "\n\n"),
                attachments: attachments,
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": args.prompts.count == 1 ? "Generating an image" : "Generating \(args.prompts.count) images"]
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
    
    private static func makeImageAttachment(prompt: String, service: ImageService, model: String) async throws -> Message.Attachment? {
        var attachments = [Message.Attachment]()
        try await ImageSession.shared
            .generate(service: service, model: model, prompt: prompt) { images in
                attachments = images.map {
                    Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: prompt))
                }
            }
        return attachments.first
    }
}
