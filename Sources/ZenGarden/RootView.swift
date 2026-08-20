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
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZenStoneMark(size: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Zen Garden")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("quiet space for attention")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                }
            }
            .padding(.bottom, 30)

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
                        .font(.system(size: 14, weight: selection == section ? .semibold : .medium, design: .rounded))
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
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    Text(model.browserBlocker.statusText)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GardenTheme.warmWhite.opacity(0.64))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
        }
        .padding(24)
        .frame(width: 245)
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
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(GardenTheme.vermilion)
            Text(title)
                .font(.system(size: 31, weight: .medium, design: .rounded))
            Text(subtitle)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(GardenTheme.softInk.opacity(0.8))
        }
    }
}
