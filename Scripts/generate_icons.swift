import Cocoa

func drawIcon(isDark: Bool) -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    
    // Taller Pastel Tab
    let tabPath = NSBezierPath()
    let tabTop: CGFloat = 880 // Increased from 744 to stick out more
    let tabBottom: CGFloat = 500
    
    tabPath.move(to: NSPoint(x: 120, y: tabTop)) 
    tabPath.line(to: NSPoint(x: 520, y: tabTop))
    tabPath.curve(to: NSPoint(x: 580, y: tabTop - 60), controlPoint1: NSPoint(x: 560, y: tabTop), controlPoint2: NSPoint(x: 580, y: tabTop - 20))
    tabPath.line(to: NSPoint(x: 580, y: tabBottom))
    tabPath.line(to: NSPoint(x: 80, y: tabBottom))
    tabPath.line(to: NSPoint(x: 80, y: tabTop - 40))
    tabPath.curve(to: NSPoint(x: 120, y: tabTop), controlPoint1: NSPoint(x: 80, y: tabTop - 20), controlPoint2: NSPoint(x: 100, y: tabTop))
    
    // More cute pastel colors! Pink -> Purple -> Blue -> Mint Green
    let tabColors = [
        NSColor(calibratedRed: 0.98, green: 0.75, blue: 0.83, alpha: 1.0).cgColor, // Pastel Pink
        NSColor(calibratedRed: 0.88, green: 0.76, blue: 0.99, alpha: 1.0).cgColor, // Pastel Purple
        NSColor(calibratedRed: 0.63, green: 0.77, blue: 0.99, alpha: 1.0).cgColor, // Pastel Blue
        NSColor(calibratedRed: 0.60, green: 0.93, blue: 0.83, alpha: 1.0).cgColor  // Pastel Mint Green
    ] as CFArray
    
    let tabGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: tabColors, locations: [0.0, 0.33, 0.66, 1.0])!
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    tabPath.fill()
    context.restoreGState()
    
    context.saveGState()
    tabPath.setClip()
    // Diagonal gradient for a dynamic pastel mix
    context.drawLinearGradient(tabGradient, start: CGPoint(x: 80, y: tabTop), end: CGPoint(x: 580, y: tabBottom), options: [])
    context.restoreGState()
    
    // Main Folder Body (Play Button Removed!)
    let bodyRect = NSRect(x: 80, y: 144, width: 864, height: 560)
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 60, yRadius: 60)
    
    let bodyColors: CFArray
    if isDark {
        bodyColors = [
            NSColor(calibratedWhite: 0.25, alpha: 0.95).cgColor,
            NSColor(calibratedWhite: 0.12, alpha: 0.95).cgColor
        ] as CFArray
    } else {
        bodyColors = [
            NSColor(calibratedWhite: 0.98, alpha: 0.95).cgColor,
            NSColor(calibratedWhite: 0.92, alpha: 0.95).cgColor
        ] as CFArray
    }
    
    let bodyGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bodyColors, locations: [0.0, 1.0])!
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -25), blur: 35, color: NSColor.black.withAlphaComponent(isDark ? 0.6 : 0.3).cgColor)
    bodyPath.fill()
    context.restoreGState()
    
    context.saveGState()
    bodyPath.setClip()
    context.drawLinearGradient(bodyGradient, start: CGPoint(x: 0, y: 704), end: CGPoint(x: 0, y: 144), options: [])
    context.restoreGState()
    
    // Glass highlight
    let highlightPath = NSBezierPath()
    highlightPath.move(to: NSPoint(x: 80, y: 704))
    highlightPath.line(to: NSPoint(x: 944, y: 704))
    highlightPath.line(to: NSPoint(x: 944, y: 560))
    highlightPath.line(to: NSPoint(x: 80, y: 560))
    highlightPath.close()
    
    context.saveGState()
    bodyPath.setClip()
    NSColor.white.withAlphaComponent(isDark ? 0.05 : 0.4).setFill()
    highlightPath.fill()
    context.restoreGState()
    
    // Border
    NSColor.white.withAlphaComponent(isDark ? 0.15 : 0.6).setStroke()
    bodyPath.lineWidth = 4
    bodyPath.stroke()
    
    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else { return }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

saveImage(drawIcon(isDark: false), to: "icon_light.png")
saveImage(drawIcon(isDark: true), to: "icon_dark.png")
print("Successfully generated light and dark icons with cute pastels and NO play button!")
