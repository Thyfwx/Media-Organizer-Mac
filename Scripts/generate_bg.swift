import Cocoa

let width: CGFloat = 600
let height: CGFloat = 400

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else { exit(1) }

// Draw background (Cute Pastel Gradient matching the app)
// Blue -> Purple -> Cyan
let colors = [
    NSColor(calibratedRed: 0.63, green: 0.77, blue: 0.99, alpha: 1.0).cgColor, // Pastel Blue
    NSColor(calibratedRed: 0.88, green: 0.76, blue: 0.99, alpha: 1.0).cgColor, // Pastel Purple
    NSColor(calibratedRed: 0.76, green: 0.91, blue: 0.98, alpha: 1.0).cgColor  // Pastel Cyan
] as CFArray

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.5, 1.0]) else { exit(1) }

context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 400), end: CGPoint(x: 600, y: 0), options: [])

// Add a frosted glass overlay effect like the app
let glassRect = NSRect(x: 0, y: 0, width: 600, height: 400)
NSColor.white.withAlphaComponent(0.2).setFill()
glassRect.fill()

// Draw Text
let text = "Drag to Install" as NSString
let font = NSFont.systemFont(ofSize: 28, weight: .bold)
let textColor = NSColor.white

// Shadow for text
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
shadow.shadowOffset = NSSize(width: 0, height: -2)
shadow.shadowBlurRadius = 10

let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: textColor,
    .shadow: shadow
]

let textSize = text.size(withAttributes: attributes)
let textRect = NSRect(x: (width - textSize.width) / 2, y: height - 80, width: textSize.width, height: textSize.height)
text.draw(in: textRect, withAttributes: attributes)

// Draw a cute white arrow
let path = NSBezierPath()
path.lineWidth = 10
path.lineCapStyle = .round
path.lineJoinStyle = .round

// Start arrow path
path.move(to: NSPoint(x: 260, y: 200))
path.line(to: NSPoint(x: 340, y: 200))

// Arrow head
path.move(to: NSPoint(x: 315, y: 220))
path.line(to: NSPoint(x: 340, y: 200))
path.line(to: NSPoint(x: 315, y: 180))

NSColor.white.withAlphaComponent(0.9).setStroke()
shadow.set()
path.stroke()

image.unlockFocus()

// Save to PNG
guard let tiffData = image.tiffRepresentation,
      let bitmapImage = NSBitmapImageRep(data: tiffData),
      let pngData = bitmapImage.representation(using: .png, properties: [:]) else { exit(1) }

let outURL = URL(fileURLWithPath: "dmg_background.png")
try pngData.write(to: outURL)
print("Successfully generated super cute pastel background!")
