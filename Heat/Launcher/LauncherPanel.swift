// Borrowed from https://github.com/mierau/hotline and modified slightly

import Cocoa
import SwiftUI

fileprivate let LAUNCHER_PANEL_SIZE: CGSize = CGSizeMake(468, 114 - 10)

class LauncherPanel: NSPanel {
    init(_ view: LauncherPanelView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: LAUNCHER_PANEL_SIZE.width, height: LAUNCHER_PANEL_SIZE.height),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .utilityWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Make sure that the panel is in front of almost all other windows
        self.isFloatingPanel = true
        self.level = .floating
        self.animationBehavior = .utilityWindow

        // Allow the panel to appear in a fullscreen space
        self.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        // Don't delete panel state when it's closed.
        self.isReleasedWhenClosed = false

        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true

        // Make it transparent, the view inside will have to set the background.
        // This is necessary because otherwise, we will have some space for the titlebar on top of the height of the
        // view itself which we don't want.
        self.isOpaque = false
        self.backgroundColor = .clear

        // Since we don't show a statusbar, this allows us to drag the window by its background instead of the titlebar.
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true

        let hostingView = NSHostingView(rootView: view.edgesIgnoringSafeArea(.top))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.sizingOptions = [.preferredContentSize]

        let visualEffectView = NSVisualEffectView(
            frame: NSRect(x: 0, y: 0, width: LAUNCHER_PANEL_SIZE.width, height: LAUNCHER_PANEL_SIZE.height)
        )
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = NSVisualEffectView.State.active
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.autoresizesSubviews = true
        visualEffectView.addSubview(hostingView)

        self.contentView = visualEffectView

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])

        hostingView.frame = visualEffectView.bounds

        if let screen = NSScreen.main {
            let rect = screen.visibleFrame
            let centerX = rect.midX - (LAUNCHER_PANEL_SIZE.width / 2)
            let centerY = rect.midY - (LAUNCHER_PANEL_SIZE.height / 2)
            self.setFrameOrigin(.init(x: centerX, y: centerY))
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
