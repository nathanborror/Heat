import SwiftUI
import AVKit

#if !os(macOS)
struct VideoView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIView {
        let view = VideoUIView(frame: .zero)
        view.setup(name: name)
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VideoView>) {
        if let view = uiView as? VideoUIView {
            view.setup(name: name)
        }
    }
}

class VideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    func setup(name: String) {
        playerLayer.player?.pause()
        NotificationCenter.default.removeObserver(self)

        let player = AVPlayer(url: Bundle.main.url(forResource: name, withExtension: "mp4")!)
        player.actionAtItemEnd = .none
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: .zero, completionHandler: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Because CALayer by default triggers an implicit animation when the
        // bounds change we need to disable them so they layer doesn't animate
        // out-of-sync with the parent views.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
#else
struct VideoView: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NSView {
        return VideoNSView(frame: .zero, name: name)
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<VideoView>) {}
}

class VideoNSView: NSView {
    private let playerLayer = AVPlayerLayer()

    init(frame: CGRect, name: String) {
        super.init(frame: frame)

        let player = AVPlayer(url: Bundle.main.url(forResource: name, withExtension: "mp4")!)
        player.actionAtItemEnd = .none
        player.play()

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        layer = playerLayer
        wantsLayer = true
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: .zero, completionHandler: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        // Because CALayer by default triggers an implicit animation when the
        // bounds change we need to disable them so they layer doesn't animate
        // out-of-sync with the parent views.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
#endif
