import SwiftUI
import QuickLook
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
                        if let url = results[index].image {
                            RenderImageView(url: url)
                        }
                    }
                }
                .frame(height: 200)
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
        guard tag.hasClosingTag else {
            return
        }
        guard let content = tag.content else {
            throw RenderTagError.missingContent
        }
        let resp = try await WebSearchSession.shared.searchImages(query: content)
        results = resp.results
    }
}

struct RenderImageView: View {
    let url: URL

    @State private var previewURL: URL? = nil

    var body: some View {
        Button {
            previewURL = url
        } label: {
            PictureView(url: url)
                .scaleEffect(1.1)
                .frame(width: 200, height: 200)
                .clipShape(.rect(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .quickLookPreview($previewURL)
    }
}
