import Cocoa

func drawIcon(isDark: Bool) -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    
    // Pastel Blue Tab
    let tabPath = NSBezierPath()
    tabPath.move(to: NSPoint(x: 120, y: 744)) 
    tabPath.line(to: NSPoint(x: 520, y: 744))
    tabPath.curve(to: NSPoint(x: 560, y: 704), controlPoint1: NSPoint(x: 540, y: 744), controlPoint2: NSPoint(x: 560, y: 724))
    tabPath.line(to: NSPoint(x: 560, y: 500))
    tabPath.line(to: NSPoint(x: 80, y: 500))
    tabPath.line(to: NSPoint(x: 80, y: 704))
    tabPath.curve(to: NSPoint(x: 120, y: 744), controlPoint1: NSPoint(x: 80, y: 724), controlPoint2: NSPoint(x: 100, y: 744))
    
    let tabColors = [
        NSColor(calibratedRed: 0.63, green: 0.77, blue: 0.99, alpha: 1.0).cgColor, // #A1C4FD
        NSColor(calibratedRed: 0.76, green: 0.91, blue: 0.98, alpha: 1.0).cgColor  // #C2E9FB
    ] as CFArray
    let tabGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: tabColors, locations: [0.0, 1.0])!
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    tabPath.fill()
    context.restoreGState()
    
    context.saveGState()
    tabPath.setClip()
    context.drawLinearGradient(tabGradient, start: CGPoint(x: 0, y: 744), end: CGPoint(x: 0, y: 500), options: [])
    context.restoreGState()
    
    // Main Folder Body
    let bodyRect = NSRect(x: 80, y: 144, width: 864, height: 560)
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 60, yRadius: 60)
    
    let bodyColors: CFArray
    if isDark {
        bodyColors = [
            NSColor(calibratedWhite: 0.2, alpha: 0.95).cgColor,
            NSColor(calibratedWhite: 0.1, alpha: 0.95).cgColor
        ] as CFArray
    } else {
        bodyColors = [
            NSColor(calibratedWhite: 0.98, alpha: 0.95).cgColor,
            NSColor(calibratedWhite: 0.9, alpha: 0.95).cgColor
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
    
    // Detailed Play Button
    let playBgRect = NSRect(x: 362, y: 274, width: 300, height: 300)
    let playBg = NSBezierPath(ovalIn: playBgRect)
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -15), blur: 25, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    playBg.fill()
    context.restoreGState()
    
    let playBgColors = [
        NSColor(calibratedWhite: 0.15, alpha: 1.0).cgColor,
        NSColor(calibratedWhite: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let playBgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: playBgColors, locations: [0.0, 1.0])!
    
    context.saveGState()
    playBg.setClip()
    context.drawLinearGradient(playBgGradient, start: CGPoint(x: 0, y: 574), end: CGPoint(x: 0, y: 274), options: [])
    context.restoreGState()
    
    NSColor(calibratedWhite: isDark ? 0.25 : 0.35, alpha: 1.0).setStroke()
    playBg.lineWidth = 6
    playBg.stroke()
    
    // Inner Ring
    let innerRingRect = NSRect(x: 392, y: 304, width: 240, height: 240)
    let innerRing = NSBezierPath(ovalIn: innerRingRect)
    NSColor.black.setFill()
    innerRing.fill()
    
    // Play Triangle
    let triangle = NSBezierPath()
    triangle.move(to: NSPoint(x: 470, y: 494))
    triangle.line(to: NSPoint(x: 610, y: 424))
    triangle.line(to: NSPoint(x: 470, y: 354))
    triangle.close()
    
    triangle.lineJoinStyle = .round
    triangle.lineWidth = 15
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 0), blur: 20, color: NSColor(calibratedRed: 0.63, green: 0.77, blue: 0.99, alpha: 1.0).cgColor)
    NSColor.white.setFill()
    triangle.fill()
    NSColor.white.setStroke()
    triangle.stroke()
    context.restoreGState()
    
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
print("Successfully generated light and dark icons!")
