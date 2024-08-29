import SwiftUI
import GenKit
import HeatKit

struct MessageAttachments: View {
    let message: Message
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(message.attachments.indices, id: \.self) { index in
                    if case .asset(let asset) = message.attachments[index] {
                        PictureView(asset: asset)
                            .aspectRatio(1.0, contentMode: .fit)    // Forces a square aspect ratio.
                            .containerRelativeFrame([.horizontal])  // Makes the frame width fill the scroll view.
                    }
                }
                Spacer()
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}
