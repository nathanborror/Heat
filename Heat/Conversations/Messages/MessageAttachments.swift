import SwiftUI
import GenKit
import HeatKit

struct MessageAttachments: View {
    let attachments: [Message.Attachment]
    
    init(_ attachments: [Message.Attachment]) {
        self.attachments = attachments
    }
    
    var body: some View {
        if !attachments.isEmpty {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(attachments.indices, id: \.self) { index in
                        switch attachments[index] {
                        case .asset(let asset):
                            PictureView(asset: asset)
                                .aspectRatio(1.0, contentMode: .fit)    // Forces a square aspect ratio.
                                .containerRelativeFrame([.horizontal])  // Makes the frame width fill the scroll view.
                        default:
                            EmptyView()
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
}
