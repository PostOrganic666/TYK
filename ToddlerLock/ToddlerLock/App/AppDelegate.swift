import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Components

    private let eventTapManager = EventTapManager()
    private let presentationManager = PresentationManager()
    private let lockWindowController = LockWindowController()
    private let lifecycleManager = LifecycleManager()
    private let permissionChecker = PermissionChecker()
    private let cursorManager = CursorManager.shared
    private let eventBus = InputEventBus.shared
    private let settings = SettingsStore.shared

    // MARK: - Windows

    private var settingsWindow: NSWindow?
    private var passwordOverlay: PasswordOverlayView?

    // MARK: - Menu Bar

    private var statusItem: NSStatusItem?

    // MARK: - State

    private var isLocked = false
    private var displayChangeObserver: NSObjectProtocol?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app shows as a regular app with dock icon and windows
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set up the main menu (enables Cmd+Q, Cmd+W, etc.)
        setupMainMenu()

        // Set up the menu bar status item
        setupStatusItem()

        showSettingsWindow()

        SoundManager.shared.maxVolume = Float(settings.maxVolume)

        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-preview"), i + 1 < args.count, let mode = PlayModeType(rawValue: args[i + 1]) {
            showPreviewWindow(mode: mode)
        }
        if args.contains("-input-spike") { runInputSpike() }
        // `-snapshot-settings <path>` writes a PNG of the Settings window and quits.
        if let i = args.firstIndex(of: "-snapshot-settings"), i + 1 < args.count {
            let path = args[i + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if let view = self?.settingsWindow?.contentView,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running for the status item
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isLocked {
            return .terminateCancel
        }
        return .terminateNow
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Toddler Mode", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdatesAction), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(showSettingsAction), keyEquivalent: ",")
        appMenu.addItem(.separator())
        #if DEBUG
        // Preview any mode in a normal window: no lock, no event tap, real
        // cursor. For building and screenshots.
        let previewMenu = NSMenu(title: "Preview")
        for mode in PlayModeType.allCases {
            let item = previewMenu.addItem(withTitle: mode.rawValue, action: #selector(previewModeAction(_:)), keyEquivalent: "")
            item.representedObject = mode.rawValue
        }
        let previewItem = appMenu.addItem(withTitle: "Preview Mode in Window", action: nil, keyEquivalent: "")
        previewItem.submenu = previewMenu
        appMenu.addItem(.separator())
        #endif
        appMenu.addItem(withTitle: "Hide Toddler Mode", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Toddler Mode", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showSettingsAction() {
        showSettingsWindow()
    }

    @objc private func checkForUpdatesAction() {
        UpdateManager.shared.checkForUpdates()
    }

    #if DEBUG
    private var previewWindow: NSWindow?

    /// Proves synthesized NSEvents reach SwiftUI and AppKit: probes at
    /// three levels (NSView.mouseDown, NSButton action, SwiftUI Button).
    private final class SpikeProbeView: NSView {
        override func mouseDown(with event: NSEvent) {
            print("SPIKE VIEW MOUSEDOWN at \(event.locationInWindow)")
            super.mouseDown(with: event)
        }
        override var acceptsFirstResponder: Bool { true }
    }

    @objc private func spikeButtonFired() { print("SPIKE NSBUTTON FIRED") }


    @objc private func previewModeAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = PlayModeType(rawValue: raw) else { return }
        showPreviewWindow(mode: mode)
    }

    /// `-preview "Play Computer"` on the command line opens this at launch.
    func showPreviewWindow(mode: PlayModeType) {
        previewWindow?.close()
        let vc = LockViewController()
        vc.currentMode = mode
        vc.isPreview = true
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Preview: \(mode.rawValue)"
        window.contentViewController = vc
        window.setContentSize(NSSize(width: 1280, height: 800))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        previewWindow = window

        // `-snapshot <path>` (and optional `-snapshot-delay <seconds>`) writes
        // one PNG of the preview window and quits. screencapture cannot see
        // windows of background-launched processes here.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-snapshot"), i + 1 < args.count {
            let path = args[i + 1]
            var delay = 1.5
            if let d = args.firstIndex(of: "-snapshot-delay"), d + 1 < args.count, let v = Double(args[d + 1]) { delay = v }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let view = window.contentView,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }

        // In the preview the real cursor works, so route real events into
        // the same handlers the lock screen uses.
        SoundManager.shared.enabled = settings.soundEnabled
        SoundManager.shared.maxVolume = Float(settings.maxVolume)
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak vc] event in
            guard let vc, event.window === vc.view.window, let mode = vc.previewMode else { return event }
            mode.handleKeyDown(keyCode: event.keyCode, characters: event.characters)
            return nil
        }
    }

    private func runInputSpike() {
        struct SpikeView: View {
            var body: some View {
                ZStack {
                    Color.gray
                    Button("Spike") { print("SPIKE SWIFTUI BUTTON FIRED") }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 200, height: 60)
                }
            }
        }
        let vc = LockViewController()
        vc.currentMode = .playComputer
        vc.isPreview = true
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = vc
        window.setContentSize(NSSize(width: 600, height: 400))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        previewWindow = window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            for sub in vc.view.subviews where sub is NSHostingView<DesktopView> { sub.removeFromSuperview() }
            let probe = SpikeProbeView(frame: vc.view.bounds)
            probe.autoresizingMask = [.width, .height]
            // Top half: SwiftUI. Bottom-left: an AppKit button.
            let host = NSHostingView(rootView: SpikeView())
            host.frame = CGRect(x: 0, y: 200, width: 600, height: 200)
            probe.addSubview(host)
            let button = NSButton(title: "AppKit", target: self, action: #selector(self.spikeButtonFired))
            button.frame = CGRect(x: 50, y: 50, width: 120, height: 40)
            probe.addSubview(button)
            vc.view.addSubview(probe)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("SPIKE clicking swiftui")
                vc.debugSynthesizeClick(topLeft: CGPoint(x: 300, y: 100))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("SPIKE clicking appkit")
                    vc.debugSynthesizeClick(topLeft: CGPoint(x: 110, y: 330))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("SPIKE DONE")
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
    #endif

    // MARK: - Status Item (Menu Bar Icon)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            // A monochrome template icon, so macOS tints it like every other
            // menu bar item in light, dark, and highlighted menu bars.
            button.image = StatusItemIcon.templateImage()
            button.imageScaling = .scaleProportionallyDown
            button.setAccessibilityLabel("Toddler Mode")
        }
        updateStatusMenu()
    }

    private func updateStatusMenu() {
        let menu = NSMenu()
        let mode = settings.selectedMode

        if isLocked {
            let lockedItem = menu.addItem(withTitle: "Locked · \(mode.rawValue)", action: nil, keyEquivalent: "")
            lockedItem.isEnabled = false
            statusItem?.button?.toolTip = "Toddler Mode is locked. \(mode.rawValue) is playing."
        } else {
            menu.addItem(withTitle: "Lock Now (\(mode.rawValue))", action: #selector(lockFromMenu), keyEquivalent: "")

            let lockWithItem = menu.addItem(withTitle: "Lock With", action: nil, keyEquivalent: "")
            let lockWithMenu = NSMenu(title: "Lock With")
            for candidate in PlayModeType.allCases {
                let item = lockWithMenu.addItem(
                    withTitle: candidate.rawValue,
                    action: #selector(lockWithModeFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = candidate.rawValue
                item.state = candidate == mode ? .on : .off
            }
            lockWithItem.submenu = lockWithMenu

            menu.addItem(.separator())
            menu.addItem(withTitle: "Settings…", action: #selector(showSettingsAction), keyEquivalent: ",")
            menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdatesAction), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit Toddler Mode", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            statusItem?.button?.toolTip = "Toddler Mode. Ready to lock: \(mode.rawValue)."
        }

        statusItem?.menu = menu
    }

    @objc private func lockFromMenu() {
        enterLockMode()
    }

    @objc private func lockWithModeFromMenu(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = PlayModeType(rawValue: raw) else { return }
        lockWithMode(mode)
    }

    /// Saves the chosen mode, then locks with it.
    private func lockWithMode(_ mode: PlayModeType) {
        settings.selectedMode = mode
        updateStatusMenu()
        enterLockMode()
    }

    // MARK: - Settings Window

    private func showSettingsWindow() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        var settingsView = SettingsView()
        settingsView.onLockNow = { [weak self] in
            self?.enterLockMode()
        }

        let hostingView = NSHostingView(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "Toddler Mode"
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    // MARK: - Lock Mode

    private func enterLockMode() {
        guard !isLocked else { return }

        isLocked = true
        updateStatusMenu()

        // Configure the exit shortcut detector
        eventTapManager.shortcutDetector = ExitShortcutDetector(
            keyCode: settings.exitKeyCode,
            requiredModifiers: settings.exitModifiers
        )

        // Set up exit shortcut handler
        eventBus.onExitShortcut = { [weak self] in
            self?.handleExitShortcut()
        }

        // Set up always-available backdoor shortcut handler
        eventBus.onBackdoorShortcut = { [weak self] in
            self?.handleBackdoorShortcut()
        }

        // Apply sound settings
        SoundManager.shared.enabled = settings.soundEnabled
        SoundManager.shared.musicEnabled = settings.musicEnabled
        SoundManager.shared.maxVolume = Float(settings.maxVolume)
        SoundManager.shared.styleVolume = PlayStyle.current.volumeScale

        // Hide settings window
        settingsWindow?.orderOut(nil)

        // Show lock screen
        lockWindowController.showLockScreen(mode: settings.selectedMode)

        // Set up password overlay on the main lock view
        setupPasswordOverlay()

        // Observe display changes so we can re-attach the password overlay
        // when windows are rebuilt by LockWindowController
        displayChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Small delay to let LockWindowController rebuild first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.setupPasswordOverlay()
            }
        }

        // Activate presentation options (hide dock, disable switching, etc.)
        presentationManager.activate()

        // Hide and disassociate cursor
        cursorManager.activate()

        // Start the event tap — this blocks all input
        let tapStarted = eventTapManager.start()
        if !tapStarted {
            print("[AppDelegate] ERROR: Event tap failed to start.")
            exitLockMode()
            showPermissionAlert()
            return
        }

        // Start lifecycle monitoring
        lifecycleManager.start(
            eventTapManager: eventTapManager,
            lockWindowController: lockWindowController,
            cursorManager: cursorManager
        )

        #if DEBUG
        lifecycleManager.onDebugAutoUnlock = { [weak self] in
            print("[AppDelegate] DEBUG: Auto-unlock triggered")
            self?.exitLockMode()
        }
        #endif

        // Start background music if enabled
        SoundManager.shared.startMusic()

        // Activate our app to ensure the lock window is frontmost
        NSApp.activate(ignoringOtherApps: true)

        print("[AppDelegate] Lock mode entered")
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Toddler Mode needs Accessibility permission to block keyboard and mouse input.

        In System Settings → Privacy & Security → Accessibility:
        1. Find Toddler Mode in the list
        2. Toggle it ON
        3. Quit and relaunch Toddler Mode
        """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            permissionChecker.openAccessibilitySettings()
        }
    }

    private func exitLockMode() {
        guard isLocked else { return }

        isLocked = false
        updateStatusMenu()

        // Remove display change observer
        if let observer = displayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            displayChangeObserver = nil
        }

        // Stop lifecycle monitoring
        lifecycleManager.stop()

        // Stop background music
        SoundManager.shared.stopMusic()

        // Stop the event tap
        eventTapManager.stop()

        // Restore presentation options
        presentationManager.deactivate()

        // Show and re-associate cursor
        cursorManager.deactivate()

        // Close lock windows
        lockWindowController.closeAll()
        passwordOverlay = nil

        // Clear event bus handlers
        eventBus.onAnimationEvent = nil
        eventBus.onPasswordEvent = nil
        eventBus.onExitShortcut = nil
        eventBus.onBackdoorShortcut = nil
        eventBus.routingMode = .animation

        // Show settings window
        showSettingsWindow()

        print("[AppDelegate] Lock mode exited")
    }

    // MARK: - Password Overlay

    /// Set up (or re-set up) the password overlay on the current main lock view.
    /// Called on initial lock and again after display changes rebuild the windows.
    private func setupPasswordOverlay() {
        guard let mainVC = lockWindowController.mainViewController,
              let window = mainVC.view.window else { return }

        // Remove old overlay if it's attached to a different view hierarchy
        passwordOverlay?.removeFromSuperview()

        let overlay = PasswordOverlayView(frame: window.frame)
        overlay.isHidden = true
        overlay.onUnlock = { [weak self] in
            self?.exitLockMode()
        }
        overlay.onCancel = { [weak self] in
            self?.dismissPasswordOverlay()
        }
        mainVC.view.addSubview(overlay)
        overlay.frame = mainVC.view.bounds
        overlay.autoresizingMask = [.width, .height]
        passwordOverlay = overlay

        eventBus.onPasswordEvent = { [weak overlay] event in
            overlay?.handleKeyEvent(event)
        }
    }

    // MARK: - Exit Shortcut Handling

    private func handleExitShortcut() {
        switch settings.unlockGate {
        case .password where KeychainManager.hasPassword:
            showPasswordOverlay(mode: .password)
        case .math:
            showPasswordOverlay(mode: .math)
        default:
            exitLockMode()
        }
    }

    /// Always-available emergency unlock: shows the overlay in PIN mode
    /// whatever the parent chose. The overlay accepts the emergency PIN.
    private func handleBackdoorShortcut() {
        showPasswordOverlay(mode: .backdoor)
    }

    private func showPasswordOverlay(mode: PasswordOverlayView.Mode) {
        eventBus.routingMode = .password
        passwordOverlay?.show(mode: mode)
    }

    private func dismissPasswordOverlay() {
        passwordOverlay?.hide()
        eventBus.routingMode = .animation
    }
}
