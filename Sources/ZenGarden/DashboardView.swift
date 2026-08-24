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
            .scrollIndicators(.hidden)
        }
    }

    private func focusCard(state: FocusState, now: Date) -> some View {
        HStack(spacing: 34) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(state.isActive ? "FOCUS IN PROGRESS" : "BEGIN A SESSION")
                        .font(GardenTypography.label(10, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(state.isActive ? GardenTheme.moss : GardenTheme.vermilion)

                    if state.isActive {
                        Text(remainingText(until: state.endsAt, now: now))
                            .font(GardenTypography.label(43, weight: .medium))
                            .monospacedDigit()
                        Text(sourceText(state.source))
                            .font(GardenTypography.body(13))
                            .foregroundStyle(GardenTheme.softInk.opacity(0.78))
                    } else {
                        Text("How long would you like to settle in?")
                            .font(GardenTypography.display(22, weight: .medium))
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

                        Button("Request a break…") {
                            showingBreakRequest = true
                        }
                        .buttonStyle(SoftButtonStyle())

                        if !model.settings.activeBreaks(at: now).isEmpty {
                            Button("Resume blocking") {
                                model.settings.endAllBreaks(at: now)
                            }
                            .buttonStyle(SoftButtonStyle())
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 9) {
                            ForEach(durations, id: \.self) { minutes in
                                Button {
                                    selectedMinutes = minutes
                                } label: {
                                    Text("\(minutes) min")
                                        .font(GardenTypography.label(13, weight: .semibold))
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

            ZenFocusRing(state: state)
                .frame(width: 178, height: 178)
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

    private var browserCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: "safari")
                    .foregroundStyle(GardenTheme.vermilion)
                Text(model.browserBlocker.statusText)
                    .font(GardenTypography.body(14, weight: .semibold))
                Spacer()
            }

            Text(model.browserBlocker.detailText)
                .font(GardenTypography.body(13))
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
                    .font(GardenTypography.body(14, weight: .semibold))
                Spacer()
            }

            Text("Your daily boundary closes distracting websites until the chosen cutoff. Every exception has a reason and stays on your Mac until the daily reflection is sent.")
                .font(GardenTypography.body(13))
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
        case .daily:
            "Your daily boundary"
        case .schedule(let name):
            "Schedule · \(name)"
        case nil:
            ""
        }
    }
}

struct ZenFocusRing: View {
    let state: FocusState

    var body: some View {
        ZenGardenMark(size: 164)
            .opacity(state.isActive ? 1 : 0.90)
            .shadow(color: GardenTheme.ink.opacity(0.10), radius: 14, y: 7)
        .accessibilityLabel(state.isActive ? "Focus active" : "Focus inactive")
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
                    ZenGardenMark(size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.isActive ? "Zen Garden is holding focus" : "Zen Garden is resting")
                            .font(GardenTypography.body(14, weight: .semibold))
                        Text(model.browserBlocker.statusText)
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

                        Text(todaySummary(today))
                            .font(GardenTypography.body(11))
                            .foregroundStyle(GardenTheme.softInk.opacity(0.68))
                    } else {
                        HStack {
                            Button("25 min") { model.settings.startSession(minutes: 25) }
                            Button("50 min") { model.settings.startSession(minutes: 50) }
                            Button("90 min") { model.settings.startSession(minutes: 90) }
                        }
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
            .frame(width: 320)
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

    private func todaySummary(_ records: [BreakRecord]) -> String {
        let minutes = records.reduce(0) { result, record in
            result + max(1, Int(record.scheduledEnd.timeIntervalSince(record.requestedAt) / 60))
        }
        let noun = records.count == 1 ? "break" : "breaks"
        return "Today · \(records.count) \(noun) · \(minutes) min requested"
    }
}
