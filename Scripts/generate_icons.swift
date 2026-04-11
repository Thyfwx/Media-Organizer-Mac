import Cocoa

func drawIcon(isDark: Bool) -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    
    // Taller Pastel Tab
    let tabPath = NSBezierPath()
    let tabTop: CGFloat = 880 
    let tabBottom: CGFloat = 500
    
    tabPath.move(to: NSPoint(x: 100, y: tabTop)) 
    tabPath.line(to: NSPoint(x: 550, y: tabTop))
    tabPath.curve(to: NSPoint(x: 600, y: tabTop - 60), controlPoint1: NSPoint(x: 580, y: tabTop), controlPoint2: NSPoint(x: 600, y: tabTop - 20))
    tabPath.line(to: NSPoint(x: 600, y: tabBottom))
    tabPath.line(to: NSPoint(x: 50, y: tabBottom))
    tabPath.line(to: NSPoint(x: 50, y: tabTop - 40))
    tabPath.curve(to: NSPoint(x: 100, y: tabTop), controlPoint1: NSPoint(x: 50, y: tabTop - 20), controlPoint2: NSPoint(x: 75, y: tabTop))
    
    // Super Cute Vibrant Pastels
    let tabColors = [
        NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.85, alpha: 1.0).cgColor,  // Vibrant Pink
        NSColor(calibratedRed: 0.85, green: 0.75, blue: 1.0, alpha: 1.0).cgColor, // Vibrant Purple
        NSColor(calibratedRed: 0.65, green: 0.85, blue: 1.0, alpha: 1.0).cgColor, // Vibrant Blue
        NSColor(calibratedRed: 0.7, green: 1.0, blue: 0.9, alpha: 1.0).cgColor    // Vibrant Mint
    ] as CFArray
    
    let tabGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: tabColors, locations: [0.0, 0.33, 0.66, 1.0])!
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    tabPath.fill()
    context.restoreGState()
    
    context.saveGState()
    tabPath.setClip()
    context.drawLinearGradient(tabGradient, start: CGPoint(x: 50, y: tabTop), end: CGPoint(x: 600, y: tabBottom), options: [])
    context.restoreGState()
    
    // Main Folder Body (LONGER - 924px wide)
    let bodyRect = NSRect(x: 50, y: 144, width: 924, height: 560)
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 70, yRadius: 70)
    
    let bodyColors: CFArray
    if isDark {
        bodyColors = [
            NSColor(calibratedWhite: 0.2, alpha: 0.9).cgColor,
            NSColor(calibratedWhite: 0.1, alpha: 0.9).cgColor
        ] as CFArray
    } else {
        bodyColors = [
            NSColor(calibratedWhite: 1.0, alpha: 0.9).cgColor,
            NSColor(calibratedWhite: 0.95, alpha: 0.9).cgColor
        ] as CFArray
    }
    
    let bodyGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bodyColors, locations: [0.0, 1.0])!
    
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -30), blur: 40, color: NSColor.black.withAlphaComponent(isDark ? 0.7 : 0.25).cgColor)
    bodyPath.fill()
    context.restoreGState()
    
    context.saveGState()
    bodyPath.setClip()
    context.drawLinearGradient(bodyGradient, start: CGPoint(x: 0, y: 704), end: CGPoint(x: 0, y: 144), options: [])
    context.restoreGState()
    
    // Glossy shine across the long body
    let highlightRect = NSRect(x: 50, y: 560, width: 924, height: 144)
    context.saveGState()
    bodyPath.setClip()
    NSColor.white.withAlphaComponent(isDark ? 0.08 : 0.45).setFill()
    highlightRect.fill()
    context.restoreGState()
    
    // Clean border
    NSColor.white.withAlphaComponent(isDark ? 0.2 : 0.7).setStroke()
    bodyPath.lineWidth = 5
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
print("Successfully generated extra-long vibrant pastel icons!")
