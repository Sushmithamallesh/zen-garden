import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedMinutes = 50
    @State private var showingBreakRequest = false

    private let durations = [25, 50, 90]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = model.settings.focusState(at: context.date)

            VStack(alignment: .leading, spacing: 12) {
                focusCard(state: state, now: context.date)
                BlockedWebsiteList()
            }
            .frame(maxWidth: 860)
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func focusCard(state: FocusState, now: Date) -> some View {
        VStack(spacing: 15) {
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(state.isActive ? GardenTheme.moss : GardenTheme.softInk.opacity(0.38))
                            .frame(width: 7, height: 7)

                        Text(state.isActive ? "FOCUS ACTIVE" : "READY")
                    }
                        .font(GardenTypography.label(10, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(state.isActive ? GardenTheme.matchaShadow : GardenTheme.softInk.opacity(0.72))

                    if state.isActive {
                        Text(remainingText(until: state.endsAt, now: now))
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        HStack(spacing: 6) {
                            Text(sourceText(state.source))
                            if let endDate = state.endsAt {
                                Text("·")
                                Text("Ends \(endDate.formatted(date: .omitted, time: .shortened))")
                            }
                        }
                        .font(GardenTypography.body(12, weight: .medium))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                    } else {
                        Text("Start a focus session")
                            .font(GardenTypography.display(22, weight: .semibold))
                    }
                }

                Spacer(minLength: 24)

                if state.isActive {
                    VStack(alignment: .trailing, spacing: 9) {
                        Button {
                            showingBreakRequest = true
                        } label: {
                            Label("Request a break", systemImage: "lock.open")
                        }
                        .buttonStyle(SoftButtonStyle())

                        HStack(spacing: 8) {
                            if state.source == .manual {
                                Button("End session") {
                                    model.settings.endManualSession()
                                }
                                .buttonStyle(.plain)
                            }

                            if !model.settings.activeBreaks(at: now).isEmpty {
                                Button("Resume blocking") {
                                    model.settings.endAllBreaks(at: now)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .font(GardenTypography.body(11, weight: .medium))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.70))
                    }
                } else {
                    HStack(spacing: 8) {
                        ForEach(durations, id: \.self) { minutes in
                            Button {
                                selectedMinutes = minutes
                            } label: {
                                Text("\(minutes) min")
                                    .font(GardenTypography.label(11, weight: .semibold))
                                    .foregroundStyle(selectedMinutes == minutes ? Color.white : GardenTheme.softInk)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(selectedMinutes == minutes ? GardenTheme.moss : GardenTheme.ink.opacity(0.055))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Button("Start") {
                            model.settings.startSession(minutes: selectedMinutes)
                        }
                        .buttonStyle(GardenPrimaryButtonStyle(compact: true))
                    }
                }
            }

            Divider()
                .overlay(GardenTheme.deepPine.opacity(0.08))

            browserStatus(isActive: state.isActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
        .sheet(isPresented: $showingBreakRequest) {
            BreakRequestView(compact: false) {
                showingBreakRequest = false
            }
            .environmentObject(model)
            .background(GardenTheme.warmWhite)
        }
    }

    private func browserStatus(isActive: Bool) -> some View {
        let symbol = model.browserBlocker.permissionHelpNeeded
            ? "exclamationmark.triangle.fill"
            : (isActive ? "checkmark.circle.fill" : "circle")
        let color = model.browserBlocker.permissionHelpNeeded
            ? GardenTheme.vermilion
            : (isActive ? GardenTheme.moss : GardenTheme.softInk.opacity(0.42))

        return HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(
                    model.browserBlocker.permissionHelpNeeded
                        ? model.browserBlocker.statusText
                        : (isActive ? "Browser blocking is on" : "Browser blocking is off")
                )
                    .font(GardenTypography.body(11, weight: .semibold))

                if model.browserBlocker.permissionHelpNeeded {
                    Text(model.browserBlocker.detailText)
                        .font(GardenTypography.body(10))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                        .lineLimit(2)
                }
            }

            Spacer()

            if model.browserBlocker.permissionHelpNeeded {
                Button("Open Automation settings") {
                    model.browserBlocker.openAutomationSettings()
                }
                .buttonStyle(SoftButtonStyle())
            }
        }
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
            "Manual session"
        case .daily:
            "Daily schedule"
        case .schedule(let name):
            "Schedule · \(name)"
        case nil:
            ""
        }
    }
}

struct MenuBarFocusView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var requestingBreak = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = model.settings.focusState(at: context.date)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 11) {
                    ZenGardenMark(size: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Zen Garden")
                            .font(GardenTypography.body(14, weight: .semibold))
                        Text(state.isActive ? "Focus active · Browser blocking on" : "Focus off")
                            .font(GardenTypography.body(11))
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                if requestingBreak {
                    BreakRequestView(compact: true) {
                        requestingBreak = false
                    }
                    .environmentObject(model)
                } else {
                    if state.isActive {
                        Text(statusTitle(state: state, until: state.endsAt))
                            .font(GardenTypography.display(20, weight: .semibold))

                        let activeBreaks = model.settings.activeBreaks(at: context.date)
                        let today = model.settings.breakRecords(on: context.date)

                        if !activeBreaks.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(activeBreaks) { record in
                                    HStack {
                                        Circle()
                                            .fill(GardenTheme.vermilion)
                                            .frame(width: 6, height: 6)
                                        Text("\(record.domain) · \(menuRemaining(until: record.scheduledEnd, now: context.date))")
                                            .font(GardenTypography.body(11, weight: .medium))
                                    }
                                }
                            }
                        }

                        HStack(spacing: 9) {
                            Button("Request a break…") { requestingBreak = true }
                                .buttonStyle(VermilionButtonStyle(compact: true))

                            if !activeBreaks.isEmpty {
                                Button("Resume now") {
                                    model.settings.endAllBreaks(at: context.date)
                                }
                                .buttonStyle(SoftButtonStyle())
                            }
                        }

                        if !today.isEmpty {
                            Text(todaySummary(today, now: context.date))
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.matchaShadow.opacity(0.82))
                        }
                    } else {
                        Text("Start a focus session")
                            .font(GardenTypography.body(12, weight: .semibold))

                        HStack {
                            Button("25 min") { model.settings.startSession(minutes: 25) }
                                .buttonStyle(SoftButtonStyle())
                            Button("50 min") { model.settings.startSession(minutes: 50) }
                                .buttonStyle(SoftButtonStyle())
                            Button("90 min") { model.settings.startSession(minutes: 90) }
                                .buttonStyle(SoftButtonStyle())
                        }
                    }
                }

                Divider()

                HStack {
                    Button {
                        openWindow(id: "main")
                        WindowController.showMainWindow()
                    } label: {
                        Label("Open Zen Garden", systemImage: "macwindow")
                            .font(GardenTypography.body(11, weight: .medium))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                            .font(GardenTypography.body(11, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(width: 320)
            .handlesZenGardenCommands()
        }
    }

    private func menuRemaining(until endDate: Date?, now: Date) -> String {
        guard let endDate else { return "Focus active" }
        let total = max(0, Int(endDate.timeIntervalSince(now)))
        let minutes = max(1, Int(ceil(Double(total) / 60)))
        return "\(minutes) min remaining"
    }

    private func statusTitle(state: FocusState, until endDate: Date?) -> String {
        if state.source == .daily, let endDate {
            return "Blocking until \(endDate.formatted(date: .omitted, time: .shortened))"
        }
        return menuRemaining(until: endDate, now: Date())
    }

    private func todaySummary(_ records: [BreakRecord], now: Date) -> String {
        let minutes = records.reduce(0) { result, record in
            result + max(1, Int(ceil(record.activeDuration(until: now) / 60)))
        }
        let noun = records.count == 1 ? "break" : "breaks"
        return "Today · \(records.count) \(noun) · \(minutes) min open"
    }
}
