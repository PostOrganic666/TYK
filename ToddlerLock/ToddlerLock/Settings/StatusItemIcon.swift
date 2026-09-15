import AppKit

/// The menu bar icon: the app's chick with a small lock, drawn as a
/// monochrome template so macOS tints it for light, dark, and highlighted
/// menu bars. Sized for the standard 18 pt status item.
enum StatusItemIcon {
    static func templateImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let s = rect.width / 18.0
            NSColor.black.setFill()

            // Body and head.
            NSBezierPath(ovalIn: NSRect(x: 1.4 * s, y: 1.1 * s, width: 12.4 * s, height: 10.2 * s)).fill()
            NSBezierPath(ovalIn: NSRect(x: 7.6 * s, y: 8.2 * s, width: 7.8 * s, height: 7.8 * s)).fill()

            // Beak.
            let beak = NSBezierPath()
            beak.move(to: NSPoint(x: 14.4 * s, y: 13.3 * s))
            beak.line(to: NSPoint(x: 17.6 * s, y: 12.1 * s))
            beak.line(to: NSPoint(x: 14.4 * s, y: 10.9 * s))
            beak.close()
            beak.fill()

            // Punch the eye and the lock back out of the silhouette.
            NSGraphicsContext.current?.compositingOperation = .destinationOut

            NSBezierPath(ovalIn: NSRect(x: 11.1 * s, y: 12.5 * s, width: 2.0 * s, height: 2.0 * s)).fill()

            // Lock shackle: a ring, cut to its top half by the lock body.
            let shackle = NSBezierPath(ovalIn: NSRect(x: 4.5 * s, y: 5.2 * s, width: 3.8 * s, height: 3.8 * s))
            shackle.lineWidth = 1.1 * s
            shackle.stroke()

            let lockBody = NSBezierPath(
                roundedRect: NSRect(x: 3.5 * s, y: 3.0 * s, width: 5.8 * s, height: 4.2 * s),
                xRadius: 1.0 * s,
                yRadius: 1.0 * s
            )
            lockBody.fill()

            // Keyhole: paint the silhouette back inside the lock body.
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: 5.6 * s, y: 4.3 * s, width: 1.6 * s, height: 1.6 * s)).fill()

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Toddler Mode"
        return image
    }
}
