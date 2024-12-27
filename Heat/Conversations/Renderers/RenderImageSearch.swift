import SwiftUI
import GenKit
import HeatKit

struct RenderImageSearch: View {
    @Environment(\.openURL) var openURL

    let tag: ContentParser.Result.Tag

    @State private var results: [WebSearchResult] = []

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(results.prefix(10).indices, id: \.self) { index in
                        if let imageURL = results[index].image {
                            PictureView(url: imageURL)
                                .scaleEffect(1.1)
                                .frame(width: width, height: height)
                                .clipShape(.rect(cornerRadius: 5))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                }
                                .onTapGesture { openURL(results[index].url) }
                        }
                    }
                }
                .frame(height: height)
            }
            .scrollIndicators(.hidden)
            .clipShape(.rect(cornerRadius: 5))

            if let content = tag.content {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            Task { try await performQuery() }
        }
    }

    func performQuery() async throws {
        guard let content = tag.content else {
            throw TagViewError.missingContent
        }
        let resp = try await WebSearchSession.shared.searchImages(query: content)
        results = resp.results
    }

    private let width: CGFloat = 200
    private let height: CGFloat = 200
}
