import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedMinutes = 50

    private let durations = [25, 50, 90]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = model.settings.focusState(at: context.date)

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    PageHeader(
                        eyebrow: "Today",
                        title: state.isActive ? "Stay with the work." : "Make room for one thing.",
                        subtitle: state.isActive
                            ? "The garden is holding distractions outside."
                            : "Choose a quiet interval. Zen Garden will close distracting websites."
                    )

                    focusCard(state: state, now: context.date)

                    HStack(alignment: .top, spacing: 18) {
                        browserCard
                        intentionCard
                    }
                }
                .padding(34)
            }
        }
    }

    private func focusCard(state: FocusState, now: Date) -> some View {
        HStack(spacing: 34) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(state.isActive ? "FOCUS IN PROGRESS" : "BEGIN A SESSION")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(state.isActive ? GardenTheme.moss : GardenTheme.vermilion)

                    if state.isActive {
                        Text(remainingText(until: state.endsAt, now: now))
                            .font(.system(size: 43, weight: .medium, design: .rounded))
                            .monospacedDigit()
                        Text(sourceText(state.source))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(GardenTheme.softInk.opacity(0.78))
                    } else {
                        Text("How long would you like to settle in?")
                            .font(.system(size: 21, weight: .medium, design: .rounded))
                    }
                }

                if state.isActive {
                    HStack(spacing: 10) {
                        if state.source == .manual {
                            Button("End session") {
                                model.settings.endManualSession()
                            }
                            .buttonStyle(SoftButtonStyle())
                        }

                        Button("Pause for 10 minutes") {
                            model.settings.pause(minutes: 10)
                        }
                        .buttonStyle(SoftButtonStyle())
                    }
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 9) {
                            ForEach(durations, id: \.self) { minutes in
                                Button {
                                    selectedMinutes = minutes
                                } label: {
                                    Text("\(minutes) min")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(selectedMinutes == minutes ? Color.white : GardenTheme.softInk)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedMinutes == minutes ? GardenTheme.moss : GardenTheme.ink.opacity(0.055))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button("Begin focus") {
                            model.settings.startSession(minutes: selectedMinutes)
                        }
                        .buttonStyle(VermilionButtonStyle())
                    }
                }
            }

            Spacer(minLength: 10)

            ZenFocusRing(state: state, now: now)
                .frame(width: 190, height: 190)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private var browserCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: "safari")
                    .foregroundStyle(GardenTheme.vermilion)
                Text(model.browserBlocker.statusText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
            }

            Text(model.browserBlocker.detailText)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)

            if model.browserBlocker.permissionHelpNeeded {
                Button("Open Automation settings") {
                    model.browserBlocker.openAutomationSettings()
                }
                .buttonStyle(SoftButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .zenCard()
    }

    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundStyle(GardenTheme.moss)
                Text("A gentle boundary")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
            }

            Text("Blocking begins only during a session or enabled schedule. Everything remains on your Mac.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .zenCard()
    }

    private func remainingText(until endDate: Date?, now: Date) -> String {
        guard let endDate else { return "In progress" }
        let total = max(0, Int(endDate.timeIntervalSince(now)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private func sourceText(_ source: FocusSource?) -> String {
        switch source {
        case .manual:
            "A session you chose"
        case .schedule(let name):
            "Schedule · \(name)"
        case nil:
            ""
        }
    }
}

struct ZenFocusRing: View {
    let state: FocusState
    let now: Date

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Ellipse()
                    .stroke(GardenTheme.rakeLine.opacity(0.16 + Double(index) * 0.025), lineWidth: 1)
                    .frame(
                        width: 176 - CGFloat(index * 24),
                        height: 112 - CGFloat(index * 13)
                    )
                    .rotationEffect(.degrees(Double(index - 2) * 5))
            }

            Circle()
                .fill(state.isActive ? GardenTheme.moss : GardenTheme.vermilion)
                .frame(width: 62, height: 62)
                .shadow(color: GardenTheme.ink.opacity(0.13), radius: 12, y: 7)

            Image(systemName: state.isActive ? "leaf.fill" : "circle.dotted")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .accessibilityLabel(state.isActive ? "Focus active" : "Focus inactive")
    }
}

struct MenuBarFocusView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = model.settings.focusState(at: context.date)

            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 11) {
                    ZenStoneMark(size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.isActive ? "Zen Garden is holding focus" : "Zen Garden is resting")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(model.browserBlocker.statusText)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                if state.isActive {
                    Text(menuRemaining(until: state.endsAt, now: context.date))
                        .font(.system(size: 27, weight: .medium, design: .rounded))
                        .monospacedDigit()

                    HStack {
                        if state.source == .manual {
                            Button("End") { model.settings.endManualSession() }
                        }
                        Button("Pause 10 min") { model.settings.pause(minutes: 10) }
                    }
                } else {
                    HStack {
                        Button("25 min") { model.settings.startSession(minutes: 25) }
                        Button("50 min") { model.settings.startSession(minutes: 50) }
                        Button("90 min") { model.settings.startSession(minutes: 90) }
                    }
                }

                Divider()

                HStack {
                    Button("Open Zen Garden") {
                        openWindow(id: "main")
                        WindowController.showMainWindow()
                    }
                    Spacer()
                    Button("Quit") { NSApp.terminate(nil) }
                }
            }
            .padding(16)
            .frame(width: 290)
        }
    }

    private func menuRemaining(until endDate: Date?, now: Date) -> String {
        guard let endDate else { return "Focus active" }
        let total = max(0, Int(endDate.timeIntervalSince(now)))
        return String(format: "%02d:%02d remaining", total / 60, total % 60)
    }
}
