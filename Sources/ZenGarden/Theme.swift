import AppKit
import SwiftUI

enum GardenTheme {
    static let ricePaper = adaptive(
        light: rgb(0.96, 0.94, 0.88),
        dark: rgb(0.067, 0.078, 0.051)
    )
    static let warmWhite = adaptive(
        light: rgb(0.995, 0.985, 0.95),
        dark: rgb(0.106, 0.125, 0.082)
    )
    static let ink = adaptive(
        light: rgb(0.16, 0.20, 0.07),
        dark: rgb(0.953, 0.941, 0.886)
    )
    static let softInk = adaptive(
        light: rgb(0.29, 0.34, 0.17),
        dark: rgb(0.741, 0.769, 0.651)
    )
    static let secondaryText = adaptive(
        light: rgb(0.40, 0.44, 0.29),
        dark: rgb(0.592, 0.627, 0.525)
    )
    static let vermilion = adaptive(
        light: rgb(0.78, 0.12, 0.075),
        dark: rgb(0.941, 0.412, 0.329)
    )
    static let softRed = adaptive(
        light: rgb(0.91, 0.37, 0.27),
        dark: rgb(0.949, 0.541, 0.439)
    )
    static let matcha = adaptive(
        light: rgb(0.408, 0.475, 0.176),
        dark: rgb(0.388, 0.463, 0.173)
    )
    static let matchaLight = adaptive(
        light: rgb(0.67, 0.72, 0.40),
        dark: rgb(0.592, 0.667, 0.373)
    )
    static let matchaPale = adaptive(
        light: rgb(0.86, 0.89, 0.70),
        dark: rgb(0.686, 0.761, 0.451)
    )
    static let matchaShadow = adaptive(
        light: rgb(0.27, 0.33, 0.12),
        dark: rgb(0.769, 0.816, 0.549)
    )
    static let earthRed = adaptive(
        light: rgb(0.64, 0.27, 0.18),
        dark: rgb(0.831, 0.424, 0.333)
    )
    static let elevatedEdge = adaptive(
        light: rgb(1, 1, 1, alpha: 0.68),
        dark: rgb(1, 1, 1, alpha: 0.10)
    )
    static let elevationShadow = adaptive(
        light: rgb(0.27, 0.33, 0.12),
        dark: rgb(0, 0, 0)
    )
    static let moss = matcha
    static let mossPressed = adaptive(
        light: rgb(0.357, 0.416, 0.141),
        dark: rgb(0.337, 0.40, 0.133)
    )
    static let leaf = matchaLight
    static let rakeLine = vermilion
    static let deepPine = matcha

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    private static func rgb(
        _ red: CGFloat,
        _ green: CGFloat,
        _ blue: CGFloat,
        alpha: CGFloat = 1
    ) -> NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}

enum GardenTypography {
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

struct ZenGardenBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GardenTheme.ricePaper

                if let heroImage = AppResources.image(named: "ZenGardenHero") {
                    Image(nsImage: heroImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .saturation(colorScheme == .dark ? 0.72 : 1)
                        .brightness(colorScheme == .dark ? -0.34 : 0)
                } else {
                    GardenFallbackBackdrop()
                }

                LinearGradient(
                    colors: backdropOverlayColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var backdropOverlayColors: [Color] {
        if reduceTransparency {
            return [
                GardenTheme.ricePaper.opacity(0.92),
                GardenTheme.ricePaper.opacity(0.86),
                GardenTheme.ricePaper.opacity(0.90)
            ]
        }

        if colorScheme == .dark {
            return [
                GardenTheme.ricePaper.opacity(0.70),
                GardenTheme.ricePaper.opacity(0.34),
                Color.black.opacity(0.42)
            ]
        }

        return [
            GardenTheme.warmWhite.opacity(0.64),
            GardenTheme.ricePaper.opacity(0.18),
            GardenTheme.deepPine.opacity(0.08)
        ]
    }
}

private struct GardenFallbackBackdrop: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(GardenTheme.ricePaper))

            for index in 0..<16 {
                let offset = CGFloat(index) * 14
                var path = Path()
                path.move(to: CGPoint(x: -24, y: size.height * 0.56 + offset))
                path.addCurve(
                    to: CGPoint(x: size.width + 24, y: size.height * 0.48 + offset),
                    control1: CGPoint(x: size.width * 0.30, y: size.height * 0.38 + offset),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.72 + offset)
                )
                context.stroke(path, with: .color(GardenTheme.rakeLine.opacity(0.22)), lineWidth: 1)
            }
        }
    }
}

@MainActor
private enum GardenIconArtwork {
    static let image: NSImage? = {
        guard let source = AppResources.image(named: "ZenGardenHero") else { return nil }

        let cropSide = min(source.size.width, source.size.height) * 0.82
        let sourceRect = NSRect(
            x: source.size.width - cropSide,
            y: 0,
            width: cropSide,
            height: cropSide
        )
        let outputSize = NSSize(width: 512, height: 512)
        let output = NSImage(size: outputSize)
        output.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(
            in: NSRect(origin: .zero, size: outputSize),
            from: sourceRect,
            operation: .copy,
            fraction: 1
        )
        output.unlockFocus()
        return output
    }()
}

struct ZenGardenMark: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            if let artwork = GardenIconArtwork.image {
                Image(nsImage: artwork)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                GardenTheme.matcha
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(GardenTheme.elevatedEdge, lineWidth: max(0.5, size * 0.018))
        }
        .drawingGroup()
    }
}

struct ZenCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(GardenTheme.warmWhite.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(GardenTheme.elevatedEdge, lineWidth: 1)
            }
            .shadow(color: GardenTheme.elevationShadow.opacity(0.09), radius: 2, y: 1)
            .shadow(color: GardenTheme.elevationShadow.opacity(0.13), radius: 18, y: 8)
    }
}

extension View {
    func zenCard() -> some View {
        modifier(ZenCardModifier())
    }
}

struct GardenPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.label(compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, compact ? 14 : 18)
            .padding(.vertical, compact ? 8 : 10)
            .background(configuration.isPressed ? GardenTheme.mossPressed : GardenTheme.moss)
            .clipShape(RoundedRectangle(cornerRadius: compact ? 9 : 11, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.label(12, weight: .semibold))
            .foregroundStyle(GardenTheme.softInk)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? GardenTheme.ink.opacity(0.10) : GardenTheme.warmWhite.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(GardenTheme.deepPine.opacity(0.12), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

@MainActor
enum AppIconRenderer {
    static func make() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()

        // Dock icons share the same slot, but their visible artwork is sized optically.
        // Keeping a transparent 24 pt margin prevents this tile from looking oversized.
        let tile = NSRect(x: 24, y: 24, width: 208, height: 208)
        let iconShape = NSBezierPath(roundedRect: tile, xRadius: 50, yRadius: 50)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.08, alpha: 0.18)
        shadow.shadowBlurRadius = 9
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()
        NSColor(calibratedRed: 0.995, green: 0.985, blue: 0.95, alpha: 1).setFill()
        iconShape.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        iconShape.addClip()

        if let artwork = GardenIconArtwork.image {
            NSGraphicsContext.current?.imageInterpolation = .high
            artwork.draw(
                in: tile,
                from: NSRect(origin: .zero, size: artwork.size),
                operation: .copy,
                fraction: 1
            )
        } else {
            NSColor(calibratedRed: 0.43, green: 0.50, blue: 0.20, alpha: 1).setFill()
            iconShape.fill()
        }

        NSGraphicsContext.restoreGraphicsState()

        NSColor(calibratedRed: 0.27, green: 0.33, blue: 0.12, alpha: 0.14).setStroke()
        iconShape.lineWidth = 1.5
        iconShape.stroke()

        image.unlockFocus()
        return image
    }

}
