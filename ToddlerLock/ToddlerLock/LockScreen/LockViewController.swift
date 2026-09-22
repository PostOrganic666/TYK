import AppKit
import SpriteKit

/// Hosts the active play mode and consumes events from the InputEventBus.
///
/// SpriteKit modes get an SKView. View modes (Play Computer, Camera,
/// Photos) get their NSView plus two extras: the virtual pointer is drawn
/// as an arrow cursor, and mouse events are synthesized as real NSEvents
/// into the window at the virtual pointer, so SwiftUI buttons, drags, and
/// scroll views behave normally. The real cursor stays hidden and
/// disassociated the whole time, which is what keeps hot corners, other
/// displays, and the menu bar out of reach.
final class LockViewController: NSViewController {
    private var container: NSView!
    private var skView: SKView?
    private var hostedView: NSView?
    private var cursorView: NSImageView?
    private var breakOverlay: NSView?
    private var activeMode: PlayMode?
    private var sessionTimer: Timer?
    private var lastClickTime: TimeInterval = 0
    private var clickCount = 1
    private let cursorManager = CursorManager.shared
    private let eventBus = InputEventBus.shared

    var currentMode: PlayModeType = .freePlay

    /// True when hosted in the DEBUG preview window (real cursor, no lock).
    var isPreview = false

    /// The running mode, for the DEBUG preview's key monitor.
    var previewMode: PlayMode? { activeMode }

    #if DEBUG
    /// Spike/test hook: click at a point (top-left coordinates) the same
    /// way the lock screen does, through synthesized NSEvents.
    func debugSynthesizeClick(topLeft point: CGPoint) {
        let pos = CGPoint(x: point.x, y: view.bounds.height - point.y)
        synthesizeMouse(.mouseMoved, at: pos)
        synthesizeMouse(.leftMouseDown, at: pos)
        synthesizeMouse(.leftMouseUp, at: pos)
    }
    #endif

    override func loadView() {
        // A real initial frame: a zero-sized view collapses any window that
        // adopts it as contentViewController.
        container = NSView(frame: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor
        self.view = container
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupMode()
        setupEventRouting()
        startSessionTimer()
    }

    override func viewWillDisappear() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        activeMode?.willEnd()
        super.viewWillDisappear()
    }

    // MARK: - Mode hosting

    static func makeMode(_ type: PlayModeType, size: CGSize) -> PlayMode {
        switch type {
        case .freePlay: return FreePlayMode(size: size)
        case .game: return GameMode(size: size)
        case .character: return CharacterMode(size: size, characterSet: SettingsStore.shared.characterSet)
        case .chill: return ChillMode(size: size)
        case .playComputer: return PlayComputerMode(size: size)
        case .camera: return CameraMode(size: size)
        case .slideshow, .explore: return PhotosMode(size: size, style: type)
        }
    }

    private func setupMode() {
        guard let window = view.window else { return }
        let size = window.contentView?.bounds.size ?? window.frame.size
        let mode = Self.makeMode(currentMode, size: size)
        activeMode = mode

        if let scene = mode.spriteScene {
            let sk = SKView(frame: container.bounds)
            sk.autoresizingMask = [.width, .height]
            sk.ignoresSiblingOrder = true
            sk.allowsTransparency = false
            #if DEBUG
            sk.showsFPS = true
            sk.showsNodeCount = true
            #endif
            container.addSubview(sk)
            sk.presentScene(scene)
            skView = sk
        } else if let hosted = mode.contentView {
            hosted.frame = container.bounds
            hosted.autoresizingMask = [.width, .height]
            container.addSubview(hosted)
            hostedView = hosted
            if !isPreview {
                addCursorView()
            }
        }
    }

    private func addCursorView() {
        let arrow = NSCursor.arrow
        let imageView = NSImageView(image: arrow.image)
        imageView.frame = CGRect(origin: .zero, size: arrow.image.size)
        imageView.wantsLayer = true
        imageView.layer?.zPosition = 1000
        imageView.layer?.shadowOpacity = 0.35
        imageView.layer?.shadowRadius = 2
        imageView.layer?.shadowOffset = CGSize(width: 0, height: -1)
        container.addSubview(imageView)
        cursorView = imageView
        moveCursorView(to: viewPosition(from: cursorManager.virtualPosition))
    }

    private func moveCursorView(to point: CGPoint) {
        guard let cursorView else { return }
        let hot = NSCursor.arrow.hotSpot
        let size = cursorView.frame.size
        // Hot spot is in a flipped image space; place the tip at `point`.
        cursorView.frame.origin = CGPoint(x: point.x - hot.x, y: point.y - (size.height - hot.y))
    }

    // MARK: - Event routing

    /// The virtual pointer lives in Core Graphics screen space (origin
    /// top-left, y grows downward, like the mouse deltas that drive it).
    /// AppKit screen space has the origin at the bottom-left of the main
    /// display, so flip y before asking the window to convert.
    private func viewPosition(from cgPoint: CGPoint) -> CGPoint {
        guard let window = view.window else { return cgPoint }
        let mainHeight = NSScreen.screens.first?.frame.height ?? window.frame.height
        let appKitPoint = CGPoint(x: cgPoint.x, y: mainHeight - cgPoint.y)
        let inWindow = window.convertPoint(fromScreen: appKitPoint)
        return view.convert(inWindow, from: nil)
    }

    private func setupEventRouting() {
        eventBus.onAnimationEvent = { [weak self] event in
            guard let self, let mode = self.activeMode else { return }

            switch event.type {
            case .keyDown:
                mode.handleKeyDown(keyCode: event.keyCode, characters: event.characters)

            case .keyUp:
                mode.handleKeyUp(keyCode: event.keyCode)

            case .mouseMove, .mouseDragged:
                let screenPos = self.cursorManager.updatePosition(delta: event.delta)
                let pos = self.viewPosition(from: screenPos)
                self.moveCursorView(to: pos)
                if event.type == .mouseDragged {
                    mode.handleMouseDragged(position: pos)
                    self.synthesizeMouse(.leftMouseDragged, at: pos)
                } else {
                    mode.handleMouseMove(position: pos)
                    self.synthesizeMouse(.mouseMoved, at: pos)
                }
                self.publishPointer(pos)

            case .mouseDown:
                let pos = self.viewPosition(from: self.cursorManager.virtualPosition)
                mode.handleMouseDown(position: pos)
                self.synthesizeMouse(.leftMouseDown, at: pos)
                ComputerInput.shared.isMouseDown = true

            case .mouseUp:
                let pos = self.viewPosition(from: self.cursorManager.virtualPosition)
                mode.handleMouseUp(position: pos)
                self.synthesizeMouse(.leftMouseUp, at: pos)
                ComputerInput.shared.isMouseDown = false

            case .scrollWheel:
                let pos = self.viewPosition(from: self.cursorManager.virtualPosition)
                mode.handleScroll(deltaY: event.scrollDeltaY, at: pos)
                self.synthesizeScroll(deltaY: event.scrollDeltaY, at: pos)

            default:
                break
            }
        }
    }

    private func publishPointer(_ pos: CGPoint) {
        guard hostedView != nil else { return }
        // Top-left coordinates for SwiftUI hover math.
        ComputerInput.shared.pointer = CGPoint(x: pos.x, y: view.bounds.height - pos.y)
    }

    /// Feed a real NSEvent to the window so SwiftUI/AppKit views react.
    private func synthesizeMouse(_ type: NSEvent.EventType, at pos: CGPoint) {
        guard hostedView != nil, let window = view.window else { return }
        if type == .leftMouseDown {
            let now = ProcessInfo.processInfo.systemUptime
            clickCount = (now - lastClickTime) < 0.4 ? clickCount + 1 : 1
            lastClickTime = now
        }
        let inWindow = view.convert(pos, to: nil)
        guard let event = NSEvent.mouseEvent(
            with: type,
            location: inWindow,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: type == .mouseMoved ? 0 : clickCount,
            pressure: type == .leftMouseUp ? 0 : 1
        ) else { return }
        // Through the queue, never window.sendEvent: AppKit/SwiftUI button
        // tracking loops pull the drag and up events from the queue, and a
        // direct sendEvent deadlocks inside them.
        NSApp.postEvent(event, atStart: false)
    }

    private func synthesizeScroll(deltaY: Double, at pos: CGPoint) {
        guard hostedView != nil, let window = view.window,
              let cg = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                               wheel1: Int32(deltaY * 8), wheel2: 0, wheel3: 0) else { return }
        // CGEvent locations are top-left screen coordinates.
        let inWindow = view.convert(pos, to: nil)
        let onScreen = window.convertPoint(toScreen: inWindow)
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        cg.location = CGPoint(x: onScreen.x, y: screenHeight - onScreen.y)
        guard let event = NSEvent(cgEvent: cg) else { return }
        NSApp.postEvent(event, atStart: false)
    }

    // MARK: - Play timer

    private var sessionLimitSeconds: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-session-limit-seconds"), i + 1 < args.count, let s = Int(args[i + 1]) {
            return s
        }
        #endif
        return SettingsStore.shared.sessionLimitMinutes * 60
    }

    private func startSessionTimer() {
        let seconds = sessionLimitSeconds
        guard seconds > 0, !isPreview else { return }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.showBreakScreen()
        }
    }

    /// The optional play timer ran out: a calm break screen covers the
    /// play content. The exit shortcut still controls the exit.
    private func showBreakScreen() {
        guard breakOverlay == nil else { return }
        SoundManager.shared.stopMusic()
        let overlay = BreakOverlayView(frame: container.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.alphaValue = 0
        container.addSubview(overlay, positioned: .below, relativeTo: cursorView)
        breakOverlay = overlay
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 1.2
            overlay.animator().alphaValue = 1
        }
        // Stop feeding the mode once the break screen is up.
        activeMode?.willEnd()
        activeMode = nil
    }
}

/// "Time for a break": a night-sky card with a moon.
final class BreakOverlayView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor(calibratedRed: 0.09, green: 0.09, blue: 0.25, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.35, alpha: 1).cgColor,
        ]
        gradient.frame = bounds
        gradient.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(gradient)

        let moon = NSTextField(labelWithString: "🌙")
        moon.font = .systemFont(ofSize: 110)
        moon.alignment = .center
        let title = NSTextField(labelWithString: "Time for a break")
        title.font = NSFont.systemFont(ofSize: 44, weight: .bold)
        title.textColor = .white
        title.alignment = .center
        let hint = NSTextField(labelWithString: "Grown-ups: use the exit shortcut")
        hint.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        hint.textColor = NSColor.white.withAlphaComponent(0.55)
        hint.alignment = .center

        let stack = NSStackView(views: [moon, title, hint])
        stack.orientation = .vertical
        stack.spacing = 18
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
