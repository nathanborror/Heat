import SwiftUI
import GenKit
import HeatKit

struct ImageSearchTag: View {
    @Environment(\.openURL) var openURL
    
    let tag: ContentParser.Result.Tag
    
    @State private var results: [WebSearchResult] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 6) {
                    ForEach(results.indices, id: \.self) { index in
                        if let imageURL = results[index].image {
                            PictureView(asset: .init(name: imageURL.absoluteString, kind: .image, location: .url))
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
            .clipShape(.rect(cornerRadius: 5))
            
            if let content = tag.content {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
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
    private let height: CGFloat = 150
}