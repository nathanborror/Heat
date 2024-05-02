import Foundation
import GenKit

extension Tool {
    
    public static var generateImages: Self =
        .init(
            type: .function,
            function: .init(
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
        )
    
    public struct GenerateImages: Codable {
        public var prompts: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public static func call(_ toolCall: ToolCall) async -> [Message] {
            do {
                let obj = try decode(toolCall.function.arguments)
                
                let imageService = try Store.shared.preferredImageService()
                let imageModel = try Store.shared.preferredImageModel()
                
                // Generate image attachments
                var attachments = [Message.Attachment]()
                for prompt in obj.prompts {
                    if let attachment = await makeImageAttachment(prompt: prompt, service: imageService, model: imageModel) {
                        attachments.append(attachment)
                    }
                }
                return [.init(
                    role: .tool,
                    content: obj.prompts.joined(separator: "\n\n"),
                    attachments: attachments,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": obj.prompts.count == 1 ? "Generating an image" : "Generating \(obj.prompts.count) images"]
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
        
        private static func makeImageAttachment(prompt: String, service: ImageService, model: String) async -> Message.Attachment? {
            var attachments = [Message.Attachment]()
            await MediaManager()
                .generate(service: service, model: model, prompt: prompt) { images in
                    attachments = images.map {
                        Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: prompt))
                    }
                }
            return attachments.first
        }
    }
}
