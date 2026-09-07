// Sklada grafike podgladu linku (Open Graph) 1200x630 dla limitwatcher.app.
//
// Po co osobny skrypt: maszyna budujaca NIE MA ImageMagick. Jest `sips` (nie
// sklada tekstu) i `swiftc`, wiec grafike rysuje AppKit. Bez tego pliku kazda
// zmiana napisu albo kolorow zaczyna sie od pisania rendera od zera.
//
// Uzycie (z katalogu repo strony):
//
//   swiftc -O narzedzia/og-image.swift -o /tmp/og-image
//   /tmp/og-image <sciezka-do-ikony-512.png> zrzuty/og-1200x630.png
//
// Ikona zrodlowa mieszka w DRUGIM repozytorium, w aplikacji:
//   ai-limit-watch/app/AppIcon.iconset/icon_512x512.png
//
// Po wygenerowaniu sprawdz rozmiar i OBEJRZYJ plik - render bez ogladania
// potrafi uciac tekst albo nasunac go na ikone:
//   sips -g pixelWidth -g pixelHeight zrzuty/og-1200x630.png
//
// Napisy sa po angielsku celowo: grafika jest wspolna dla wersji EN i PL,
// tak samo jak nazwa produktu. Po polsku jest tylko og:image:alt na stronie PL.

import AppKit

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("Uzycie: og-image <ikona-512.png> <wyjscie.png>\n".data(using: .utf8)!)
    exit(2)
}
let iconPath = args[1]
let outPath = args[2]

let W = 1200.0, H = 630.0

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.saveGraphicsState()
let gc = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gc
let ctx = gc.cgContext
ctx.setShouldAntialias(true)
ctx.setShouldSmoothFonts(true)

// Background: warm off-white
NSColor(red: 0.975, green: 0.973, blue: 0.985, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// Soft violet/blue halo behind the icon (top-left) and faint blue at bottom-right
func halo(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: NSColor) {
    let cs = CGColorSpaceCreateDeviceRGB()
    let g = CGGradient(colorsSpace: cs, colors: [color.withAlphaComponent(0.55).cgColor, color.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: 0, endCenter: CGPoint(x: cx, y: cy), endRadius: r, options: [])
}
halo(230, 330, 420, NSColor(red: 0.80, green: 0.76, blue: 0.99, alpha: 1))
halo(1150, 40, 380, NSColor(red: 0.78, green: 0.84, blue: 1.0, alpha: 1))

// Icon with soft shadow
let icon = NSImage(contentsOfFile: iconPath)!
let iconSize = 236.0
let iconRect = NSRect(x: 96, y: (H - iconSize) / 2 + 22, width: iconSize, height: iconSize)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 36, color: NSColor(red: 0.35, green: 0.30, blue: 0.75, alpha: 0.28).cgColor)
icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
ctx.restoreGState()

// Text block
let textX = 392.0
let textW = W - textX - 60
let ink = NSColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)
let inkSoft = NSColor(red: 0.36, green: 0.37, blue: 0.46, alpha: 1)

func font(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    return NSFont.systemFont(ofSize: size, weight: weight)
}
func para(_ spacing: CGFloat) -> NSParagraphStyle {
    let p = NSMutableParagraphStyle(); p.lineSpacing = spacing; p.lineBreakMode = .byWordWrapping; return p
}

let title = NSAttributedString(string: "AI-limit-watcher", attributes: [
    .font: font(74, .bold), .foregroundColor: ink, .kern: -1.6, .paragraphStyle: para(0)])
let tagline = NSAttributedString(string: "Know the minute your Claude Code limit comes back.", attributes: [
    .font: font(38, .medium), .foregroundColor: inkSoft, .kern: -0.3, .paragraphStyle: para(6)])

let tSize = title.boundingRect(with: NSSize(width: textW, height: 400), options: [.usesLineFragmentOrigin]).size
let gSize = tagline.boundingRect(with: NSSize(width: textW, height: 400), options: [.usesLineFragmentOrigin]).size
let gap = 26.0
let blockH = tSize.height + gap + gSize.height
let blockTop = (H + blockH) / 2 + 22   // flipped coords: y grows upward
title.draw(with: NSRect(x: textX, y: blockTop - tSize.height, width: textW, height: tSize.height), options: [.usesLineFragmentOrigin])
tagline.draw(with: NSRect(x: textX, y: blockTop - tSize.height - gap - gSize.height, width: textW, height: gSize.height), options: [.usesLineFragmentOrigin])

// Accent rule under title
let ruleY = blockTop - tSize.height - gap / 2 - 2
let cs = CGColorSpaceCreateDeviceRGB()
let rg = CGGradient(colorsSpace: cs, colors: [NSColor(red: 0.42, green: 0.49, blue: 0.98, alpha: 1).cgColor, NSColor(red: 0.62, green: 0.50, blue: 0.96, alpha: 1).cgColor] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: CGRect(x: textX + 2, y: ruleY - 2, width: 88, height: 5), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil))
ctx.clip()
ctx.drawLinearGradient(rg, start: CGPoint(x: textX, y: 0), end: CGPoint(x: textX + 90, y: 0), options: [])
ctx.restoreGState()

// Footer
let footer = NSAttributedString(string: "limitwatcher.app", attributes: [
    .font: font(24, .medium), .foregroundColor: NSColor(red: 0.50, green: 0.51, blue: 0.60, alpha: 1), .kern: 0.4])
footer.draw(at: NSPoint(x: textX, y: 70))

NSGraphicsContext.restoreGraphicsState()
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("Zapisano \(outPath)")
