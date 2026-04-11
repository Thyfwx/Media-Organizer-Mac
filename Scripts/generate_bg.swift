import Cocoa
let image = NSImage(size: NSSize(width: 600, height: 400))
image.lockFocus()
let context = NSGraphicsContext.current!.cgContext
let colors = [
    NSColor(calibratedRed: 0.85, green: 0.7, blue: 1.0, alpha: 1.0).cgColor, // Pastel Purple
    NSColor(calibratedRed: 0.6, green: 0.8, blue: 1.0, alpha: 1.0).cgColor  // Pastel Blue
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 400), end: CGPoint(x: 600, y: 0), options: [])

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
    .foregroundColor: NSColor.white
]
"Drag App to Applications".draw(at: CGPoint(x: 160, y: 320), withAttributes: attributes)
image.unlockFocus()
let pngData = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try! pngData.write(to: URL(fileURLWithPath: "/Users/xavierscott/Documents/Media Organizer/Scripts/dmg_background.png"))
