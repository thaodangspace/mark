import Cocoa

class IconManager {
    static let shared = IconManager()
    
    private init() {}
    
    /// Creates a programmatic icon for the menu bar
    func createMenuBarIcon() -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Set up the graphics context
        guard NSGraphicsContext.current != nil else {
            image.unlockFocus()
            return nil
        }
        
        // Outer circle (recording button outline)
        let outerRect = NSRect(x: 2, y: 2, width: 14, height: 14)
        let outerPath = NSBezierPath(ovalIn: outerRect)
        outerPath.lineWidth = 1.5
        NSColor.labelColor.setStroke()
        outerPath.stroke()
        
        // Inner circle (recording dot)
        let innerRect = NSRect(x: 6, y: 6, width: 6, height: 6)
        let innerPath = NSBezierPath(ovalIn: innerRect)
        NSColor.systemRed.setFill()
        innerPath.fill()
        
        image.unlockFocus()
        image.isTemplate = true  // Makes it adapt to light/dark mode
        
        return image
    }
    
    /// Creates app icons for the bundle
    func createAppIcon(size: NSSize) -> NSImage? {
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        guard NSGraphicsContext.current != nil else {
            image.unlockFocus()
            return nil
        }
        
        // Create a gradient background
        let gradient = NSGradient(colors: [
            NSColor.systemBlue,
            NSColor.systemPurple
        ])
        
        let rect = NSRect(origin: .zero, size: size)
        gradient?.draw(in: rect, angle: 45)
        
        // Draw the recording icon in the center
        let iconSize = min(size.width, size.height) * 0.6
        let iconRect = NSRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        
        // Outer circle
        let outerPath = NSBezierPath(ovalIn: iconRect)
        outerPath.lineWidth = size.width * 0.05
        NSColor.white.setStroke()
        outerPath.stroke()
        
        // Inner circle
        let innerSize = iconSize * 0.4
        let innerRect = NSRect(
            x: (size.width - innerSize) / 2,
            y: (size.height - innerSize) / 2,
            width: innerSize,
            height: innerSize
        )
        let innerPath = NSBezierPath(ovalIn: innerRect)
        NSColor.systemRed.setFill()
        innerPath.fill()
        
        image.unlockFocus()
        
        return image
    }
}
