import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case websites = "Websites"
    case schedules = "Schedules"
    case settings = "Settings"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .focus: "circle.inset.filled"
        case .websites: "safari"
        case .schedules: "calendar"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var selection: AppSection = .focus

    var body: some View {
        ZStack {
            ZenGardenBackdrop()

            HStack(spacing: 0) {
                sidebar
                Rectangle()
                    .fill(GardenTheme.deepPine.opacity(0.14))
                    .frame(width: 1)
                content
            }
        }
        .foregroundStyle(GardenTheme.ink)
        .onOpenURL { url in
            handleExternalCommand(url)
        }
    }

    private func handleExternalCommand(_ url: URL) {
        guard url.scheme?.lowercased() == "zengarden" else { return }
        switch url.host?.lowercased() {
        case "request-break":
            openWindow(id: "break-request")
            NSApp.activate(ignoringOtherApps: true)
        case "resume":
            model.settings.endAllBreaks()
        case "open":
            WindowController.showMainWindow()
        default:
            break
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZenGardenMark(size: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Zen Garden")
                        .font(GardenTypography.display(23, weight: .semibold))
                    Text("quiet space for attention")
                        .font(GardenTypography.body(11))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                }
            }
            .padding(.bottom, 28)

            VStack(spacing: 8) {
                ForEach(AppSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        HStack(spacing: 12) {
                            Capsule()
                                .fill(selection == section ? GardenTheme.vermilion : Color.clear)
                                .frame(width: 3, height: 18)
                            Image(systemName: section.symbol)
                                .frame(width: 18)
                            Text(section.rawValue)
                            Spacer()
                        }
                        .font(GardenTypography.label(14, weight: selection == section ? .semibold : .medium))
                        .foregroundStyle(selection == section ? GardenTheme.ink : GardenTheme.softInk)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .background(selection == section ? GardenTheme.warmWhite.opacity(0.92) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(selection == section ? GardenTheme.deepPine.opacity(0.10) : Color.clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let state = model.settings.focusState(at: context.date)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(state.isActive ? GardenTheme.moss : GardenTheme.rakeLine)
                            .frame(width: 7, height: 7)
                        Text(state.isActive ? "Focus is active" : "Garden is resting")
                            .font(GardenTypography.label(12, weight: .semibold))
                    }
                    Text(model.browserBlocker.statusText)
                        .font(GardenTypography.body(11))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GardenTheme.warmWhite.opacity(0.64))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
        }
        .padding(22)
        .frame(width: 250)
        .background(.ultraThinMaterial)
        .background(GardenTheme.warmWhite.opacity(0.84))
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch selection {
            case .focus:
                DashboardView()
            case .websites:
                WebsitesView()
            case .schedules:
                SchedulesView()
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(model)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow.uppercased())
                .font(GardenTypography.label(10, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(GardenTheme.vermilion)
            Text(title)
                .font(GardenTypography.display(34, weight: .semibold))
                .tracking(-0.35)
            Text(subtitle)
                .font(GardenTypography.body(14))
                .foregroundStyle(GardenTheme.softInk.opacity(0.8))
                .lineSpacing(2)
        }
    }
}
