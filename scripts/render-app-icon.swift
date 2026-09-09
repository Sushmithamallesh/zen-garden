#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: render-app-icon.swift SOURCE_IMAGE OUTPUT_ICONSET\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

guard let source = NSImage(contentsOf: sourceURL) else {
    fputs("Could not read icon source at \(sourceURL.path)\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL,
    withIntermediateDirectories: true
)

let variants: [(filename: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func renderIcon(pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let canvas = CGFloat(pixels)
    bitmap.size = NSSize(width: canvas, height: canvas)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill()

    let margin = canvas * 0.09375
    let tile = NSRect(
        x: margin,
        y: margin,
        width: canvas - (margin * 2),
        height: canvas - (margin * 2)
    )
    let shape = NSBezierPath(
        roundedRect: tile,
        xRadius: canvas * 0.1953125,
        yRadius: canvas * 0.1953125
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.08, alpha: 0.18)
    shadow.shadowBlurRadius = canvas * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: canvas * -0.016)
    shadow.set()
    NSColor(calibratedRed: 0.995, green: 0.985, blue: 0.95, alpha: 1).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGraphicsContext.current?.imageInterpolation = .high

    let cropSide = min(source.size.width, source.size.height) * 0.82
    let sourceRect = NSRect(
        x: source.size.width - cropSide,
        y: 0,
        width: cropSide,
        height: cropSide
    )
    source.draw(in: tile, from: sourceRect, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    NSColor(calibratedRed: 0.27, green: 0.33, blue: 0.12, alpha: 0.14).setStroke()
    shape.lineWidth = max(0.5, canvas * 0.006)
    shape.stroke()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

for variant in variants {
    let data = try renderIcon(pixels: variant.pixels)
    try data.write(to: outputURL.appendingPathComponent(variant.filename))
}
