import SwiftUI

private enum RootSheet: String, Identifiable {
    case schedules
    case settings

    var id: String { rawValue }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var presentedSheet: RootSheet?

    var body: some View {
        ZStack {
            ZenGardenBackdrop()
            DashboardView()
        }
        .foregroundStyle(GardenTheme.ink)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    presentedSheet = .schedules
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityLabel("Schedules")
                .help("Schedules")

                Button {
                    presentedSheet = .settings
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .help("Settings")
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            ZStack {
                ZenGardenBackdrop()

                switch sheet {
                case .schedules:
                    SchedulesView()
                case .settings:
                    SettingsView()
                }
            }
            .foregroundStyle(GardenTheme.ink)
            .frame(minWidth: 760, minHeight: 610)
            .environmentObject(model)
        }
        .handlesZenGardenCommands()
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .font(GardenTypography.label(10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(GardenTheme.vermilion)
            }
            Text(title)
                .font(GardenTypography.display(34, weight: .semibold))
                .tracking(-0.35)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(GardenTypography.body(14))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.8))
                    .lineSpacing(2)
            }
        }
    }
}
