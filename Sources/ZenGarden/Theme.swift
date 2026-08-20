import AppKit
import SwiftUI

enum GardenTheme {
    static let ricePaper = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let warmWhite = Color(red: 0.995, green: 0.985, blue: 0.95)
    static let ink = Color(red: 0.055, green: 0.14, blue: 0.09)
    static let softInk = Color(red: 0.18, green: 0.28, blue: 0.21)
    static let vermilion = Color(red: 0.78, green: 0.12, blue: 0.075)
    static let softRed = Color(red: 0.91, green: 0.37, blue: 0.27)
    static let moss = Color(red: 0.16, green: 0.38, blue: 0.21)
    static let leaf = Color(red: 0.32, green: 0.55, blue: 0.28)
    static let rakeLine = Color(red: 0.78, green: 0.12, blue: 0.075)
    static let deepPine = Color(red: 0.035, green: 0.20, blue: 0.11)
}

struct ZenGardenBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GardenTheme.ricePaper

                Image("ZenGardenHero", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        GardenTheme.warmWhite.opacity(0.64),
                        GardenTheme.ricePaper.opacity(0.18),
                        GardenTheme.deepPine.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct ZenStoneMark: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle()
                .fill(GardenTheme.deepPine)
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(GardenTheme.ricePaper.opacity(0.64 - Double(index) * 0.12), lineWidth: 1)
                    .frame(
                        width: size * (0.42 + CGFloat(index) * 0.18),
                        height: size * (0.24 + CGFloat(index) * 0.13)
                    )
            }
            Circle()
                .fill(GardenTheme.vermilion)
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: size * 0.19, y: -size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

struct ZenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .background(GardenTheme.warmWhite.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(GardenTheme.deepPine.opacity(0.11), lineWidth: 1)
            }
            .shadow(color: GardenTheme.deepPine.opacity(0.09), radius: 18, y: 8)
    }
}

extension View {
    func zenCard() -> some View {
        modifier(ZenCardModifier())
    }
}

struct VermilionButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 13 : 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, compact ? 15 : 20)
            .padding(.vertical, compact ? 8 : 11)
            .background(configuration.isPressed ? GardenTheme.vermilion.opacity(0.78) : GardenTheme.vermilion)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(GardenTheme.softInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(GardenTheme.ink.opacity(configuration.isPressed ? 0.10 : 0.055))
            .clipShape(Capsule())
    }
}

enum AppIconRenderer {
    static func make() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor(calibratedRed: 0.035, green: 0.20, blue: 0.11, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 58, yRadius: 58).fill()

        NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.88, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 42, y: 53, width: 172, height: 150)).fill()

        for index in 0..<4 {
            NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.075, alpha: 0.58 + CGFloat(index) * 0.08).setStroke()
            let inset = CGFloat(54 + index * 14)
            let path = NSBezierPath(ovalIn: NSRect(x: inset, y: 84 - CGFloat(index * 2), width: 256 - inset * 2, height: 86 + CGFloat(index * 4)))
            path.lineWidth = 3
            path.stroke()
        }

        NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.075, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 116, y: 116, width: 24, height: 24)).fill()

        image.unlockFocus()
        return image
    }
}
