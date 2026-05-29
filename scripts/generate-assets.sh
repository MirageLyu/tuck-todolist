#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/assets"
ICONSET_DIR="$ASSETS_DIR/Tuck.iconset"
DRAWER="$ASSETS_DIR/.generate-assets.swift"

mkdir -p "$ASSETS_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

cat > "$DRAWER" <<'SWIFT'
import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TuckAssets", code: 1)
    }
    try data.write(to: url)
}

func drawTuckIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let inset = size * 0.08
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let radius = size * 0.2
    let base = NSBezierPath(roundedRect: iconRect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.current?.saveGraphicsState()
    base.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.23, green: 0.60, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.23, green: 0.34, blue: 0.92, alpha: 1),
        NSColor(calibratedRed: 0.40, green: 0.25, blue: 0.82, alpha: 1)
    ])!
    gradient.draw(in: iconRect, angle: -35)

    NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: iconRect.minX - size * 0.10, y: iconRect.midY, width: size * 0.65, height: size * 0.55)).fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor(calibratedWhite: 0, alpha: 0.18).setStroke()
    base.lineWidth = size * 0.012
    base.stroke()

    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: iconRect.maxX - size * 0.26, y: iconRect.maxY))
    fold.line(to: NSPoint(x: iconRect.maxX, y: iconRect.maxY))
    fold.line(to: NSPoint(x: iconRect.maxX, y: iconRect.maxY - size * 0.26))
    fold.close()
    NSColor(calibratedWhite: 1, alpha: 0.34).setFill()
    fold.fill()
    NSColor(calibratedWhite: 1, alpha: 0.25).setStroke()
    fold.lineWidth = size * 0.008
    fold.stroke()

    let cardRect = NSRect(x: size * 0.27, y: size * 0.25, width: size * 0.46, height: size * 0.50)
    let card = NSBezierPath(roundedRect: cardRect, xRadius: size * 0.045, yRadius: size * 0.045)
    NSColor(calibratedWhite: 1, alpha: 0.94).setFill()
    card.fill()

    NSColor(calibratedRed: 0.18, green: 0.38, blue: 0.95, alpha: 1).setStroke()
    for i in 0..<3 {
        let y = cardRect.maxY - size * 0.14 - CGFloat(i) * size * 0.125
        let check = NSBezierPath()
        check.move(to: NSPoint(x: cardRect.minX + size * 0.08, y: y + size * 0.005))
        check.line(to: NSPoint(x: cardRect.minX + size * 0.115, y: y - size * 0.03))
        check.line(to: NSPoint(x: cardRect.minX + size * 0.18, y: y + size * 0.045))
        check.lineWidth = size * 0.018
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        check.stroke()

        let line = NSBezierPath()
        line.move(to: NSPoint(x: cardRect.minX + size * 0.23, y: y))
        line.line(to: NSPoint(x: cardRect.maxX - size * 0.07, y: y))
        line.lineWidth = size * 0.018
        line.lineCapStyle = .round
        line.stroke()
    }

    image.unlockFocus()
    return image
}

func drawDMGBackground() -> NSImage {
    let size = NSSize(width: 640, height: 380)
    let image = NSImage(size: size)
    image.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1).setFill()
    rect.fill()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.92, green: 0.96, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.98, green: 0.96, blue: 1.0, alpha: 1)
    ])!
    gradient.draw(in: rect, angle: 0)

    NSColor(calibratedRed: 0.24, green: 0.36, blue: 0.92, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: NSRect(x: -80, y: 210, width: 260, height: 210)).fill()
    NSColor(calibratedRed: 0.24, green: 0.65, blue: 1.0, alpha: 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: 470, y: -80, width: 240, height: 220)).fill()

    let title = "Install Tuck"
    let subtitle = "Drag Tuck to Applications"
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 28, weight: .semibold),
        .foregroundColor: NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.22, alpha: 1)
    ]
    let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 15, weight: .medium),
        .foregroundColor: NSColor(calibratedRed: 0.34, green: 0.38, blue: 0.48, alpha: 1)
    ]
    title.draw(at: NSPoint(x: 56, y: 310), withAttributes: titleAttrs)
    subtitle.draw(at: NSPoint(x: 56, y: 284), withAttributes: subtitleAttrs)

    NSColor(calibratedRed: 0.28, green: 0.40, blue: 0.92, alpha: 0.32).setStroke()
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 260, y: 176))
    arrow.curve(to: NSPoint(x: 382, y: 176), controlPoint1: NSPoint(x: 302, y: 210), controlPoint2: NSPoint(x: 344, y: 210))
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    arrow.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 382, y: 176))
    head.line(to: NSPoint(x: 363, y: 190))
    head.move(to: NSPoint(x: 382, y: 176))
    head.line(to: NSPoint(x: 363, y: 162))
    head.lineWidth = 4
    head.lineCapStyle = .round
    head.stroke()

    image.unlockFocus()
    return image
}

try savePNG(drawTuckIcon(size: 1024), to: root.appendingPathComponent("Tuck-1024.png"))
try savePNG(drawDMGBackground(), to: root.appendingPathComponent("dmg-background.png"))
SWIFT

swift "$DRAWER" "$ASSETS_DIR"

for spec in \
  "16 icon_16x16.png" \
  "32 icon_16x16@2x.png" \
  "32 icon_32x32.png" \
  "64 icon_32x32@2x.png" \
  "128 icon_128x128.png" \
  "256 icon_128x128@2x.png" \
  "256 icon_256x256.png" \
  "512 icon_256x256@2x.png" \
  "512 icon_512x512.png" \
  "1024 icon_512x512@2x.png"; do
  read -r size name <<< "$spec"
  sips -z "$size" "$size" "$ASSETS_DIR/Tuck-1024.png" --out "$ICONSET_DIR/$name" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$ASSETS_DIR/Tuck.icns"
rm -rf "$ICONSET_DIR" "$DRAWER"
printf 'Generated %s and %s\n' "$ASSETS_DIR/Tuck.icns" "$ASSETS_DIR/dmg-background.png"
