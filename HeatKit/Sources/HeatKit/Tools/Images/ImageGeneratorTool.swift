import Foundation
import SharedKit
import GenKit

public struct ImageGeneratorTool {

    public struct Arguments: Codable {
        public var prompts: [String]
    }

    public static let function = Tool.Function(
        name: "image_generator",
        description: "Return thoughtful, detailed image prompts.",
        parameters: .object(
            properties: [
                "prompts": .array(
                    description: "A list of detailed prompts describing images to generate.",
                    items: .string(),
                    minItems: 1,
                    maxItems: 9
                ),
            ],
            required: ["prompts"]
        )
    )
}

extension ImageGeneratorTool.Arguments {

    public init(_ arguments: String?) throws {
        guard let arguments, let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension ImageGeneratorTool {

    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function?.arguments)
            let (service, model) = try await API.shared.preferredImageService()

            // Generate image attachments
            var contents = [Message.Content]()
            for prompt in args.prompts {
                contents += try await makeImages(prompt: prompt, service: service, model: model)
            }
            return [.init(
                role: .tool,
                contents: contents + [.text(args.prompts.joined(separator: "\n\n"))],
                toolCallID: toolCall.id,
                name: toolCall.function?.name,
                metadata: ["label": args.prompts.count == 1 ? "Generating an image" : .string("Generating \(args.prompts.count) images")]
            )]
        } catch {
            return [.init(
                role: .tool,
                content: "Tool Failed: \(error.localizedDescription)",
                toolCallID: toolCall.id,
                name: toolCall.function?.name
            )]
        }
    }

    private static func makeImages(prompt: String, service: ImageService, model: Model) async throws -> [Message.Content] {
        var out = [Message.Content]()
        try await ImageSession.shared.generate(service: service, model: model, prompt: prompt) { images in
            for imageData in images {
                let filename = "\(String.id).png"
                let url = URL.documentsDirectory.appending(path: "images").appending(path: filename)
                try imageData.write(to: url, options: .atomic, createDirectories: true)
                out += [.image(.init(url: url, format: .png, detail: prompt))]
            }
        }
        return out
    }
}
