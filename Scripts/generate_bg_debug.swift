import Cocoa
let width: CGFloat = 600
let height: CGFloat = 400
let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()
let context = NSGraphicsContext.current!.cgContext
let colors = [NSColor.red.cgColor, NSColor.blue.cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 600, y: 400), options: [])
image.unlockFocus()
let tiffData = image.tiffRepresentation!
let bitmapImage = NSBitmapImageRep(data: tiffData)!
let pngData = bitmapImage.representation(using: .png, properties: [:])!
try! pngData.write(to: URL(fileURLWithPath: "/Users/xavierscott/Documents/Media Organizer/Scripts/dmg_background_debug.png"))
