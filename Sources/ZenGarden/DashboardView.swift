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
                        .foregroundStyle(state.isActive ? GardenTheme.matchaShadow : GardenTheme.secondaryText)

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
                        .foregroundStyle(GardenTheme.secondaryText)
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
                            Label("Unblock a website", systemImage: "lock.open")
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
                        .foregroundStyle(GardenTheme.secondaryText)
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
                        : (isActive ? "Blocking is on" : "Blocking is off")
                )
                    .font(GardenTypography.body(11, weight: .semibold))

                if model.browserBlocker.permissionHelpNeeded {
                    Text(model.browserBlocker.detailText)
                        .font(GardenTypography.body(10))
                        .foregroundStyle(GardenTheme.secondaryText)
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

    private let durations = [25, 50, 90]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = model.settings.focusState(at: context.date)
            let activeBreaks = model.settings.activeBreaks(at: context.date)
            let blockedCount = model.settings.websitesForBlocking(at: context.date)
                .filter {
                    $0.isEnabled
                        && !model.settings.isDomainTemporarilyAllowed($0.domain, at: context.date)
                }
                .count

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(GardenTheme.moss)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Zen Garden")
                            .font(GardenTypography.body(13, weight: .semibold))
                        Text(headerStatus(state: state, blockedCount: blockedCount))
                            .font(GardenTypography.body(10, weight: .medium))
                            .foregroundStyle(GardenTheme.secondaryText)
                    }

                    Spacer(minLength: 8)

                    Menu {
                        Button {
                            openDashboard()
                        } label: {
                            Label("Open dashboard", systemImage: "macwindow")
                        }

                        Divider()

                        Button(role: .destructive) {
                            NSApp.terminate(nil)
                        } label: {
                            Label("Quit Zen Garden", systemImage: "power")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GardenTheme.softInk.opacity(0.78))
                            .frame(width: 30, height: 30)
                            .background(GardenTheme.ink.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("More")
                }
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 8)

                Rectangle()
                    .fill(GardenTheme.ink.opacity(0.07))
                    .frame(height: 1)

                if requestingBreak {
                    BreakRequestView(compact: true) {
                        requestingBreak = false
                    }
                    .environmentObject(model)
                    .padding(10)
                } else {
                    if state.isActive {
                        VStack(alignment: .leading, spacing: 9) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(GardenTheme.moss)
                                            .frame(width: 6, height: 6)
                                        Text("FOCUS ACTIVE")
                                            .font(GardenTypography.label(9, weight: .bold))
                                            .tracking(1.25)
                                    }
                                    .foregroundStyle(GardenTheme.matchaShadow)

                                    Spacer()

                                    Text(sourceLabel(state.source))
                                        .font(GardenTypography.body(10, weight: .medium))
                                        .foregroundStyle(GardenTheme.matchaShadow)
                                }

                                Text(remainingClock(until: state.endsAt, now: context.date))
                                    .font(.system(size: 31, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(GardenTheme.ink)

                                if let endDate = state.endsAt {
                                    Text("Ends \(endDate.formatted(date: .omitted, time: .shortened))")
                                        .font(GardenTypography.body(10, weight: .medium))
                                        .foregroundStyle(GardenTheme.matchaShadow)
                                }
                            }
                            .padding(12)
                            .background(GardenTheme.matchaPale.opacity(0.34))
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(GardenTheme.matchaShadow.opacity(0.08), lineWidth: 1)
                            }

                            if !activeBreaks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("UNBLOCKED")
                                        .font(GardenTypography.label(9, weight: .bold))
                                        .tracking(1.1)
                                        .foregroundStyle(GardenTheme.vermilion)

                                    ForEach(activeBreaks) { record in
                                        HStack(spacing: 8) {
                                            Image(systemName: "lock.open.fill")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(GardenTheme.vermilion)
                                            Text(record.domain)
                                                .font(GardenTypography.body(11, weight: .semibold))
                                            Spacer()
                                            Text(menuRemaining(until: record.scheduledEnd, now: context.date))
                                                .font(GardenTypography.body(10, weight: .medium))
                                                .monospacedDigit()
                                                .foregroundStyle(GardenTheme.secondaryText)
                                        }
                                    }

                                    Button {
                                        model.settings.endAllBreaks(at: context.date)
                                    } label: {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                            Text("Resume blocking")
                                        }
                                            .font(GardenTypography.body(11, weight: .medium))
                                    }
                                    .buttonStyle(MenuBarSecondaryButtonStyle())
                                }
                            }

                            Button {
                                requestingBreak = true
                            } label: {
                                HStack(spacing: 9) {
                                    Image(systemName: "lock.open")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Unblock a website")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .opacity(0.55)
                                }
                            }
                            .buttonStyle(MenuBarPrimaryButtonStyle())

                            if model.browserBlocker.permissionHelpNeeded {
                                Button {
                                    model.browserBlocker.openAutomationSettings()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("Browser access needed")
                                        Spacer()
                                        Text("Fix")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .buttonStyle(MenuBarWarningButtonStyle())
                            }
                        }
                        .padding(10)
                    } else {
                        VStack(alignment: .leading, spacing: 9) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(GardenTheme.softInk.opacity(0.36))
                                        .frame(width: 6, height: 6)
                                    Text("READY")
                                        .font(GardenTypography.label(9, weight: .bold))
                                        .tracking(1.25)
                                }
                                .foregroundStyle(GardenTheme.secondaryText)

                                Text("Start a focus session")
                                    .font(GardenTypography.display(19, weight: .semibold))

                                Text("Choose a duration")
                                    .font(GardenTypography.body(10, weight: .medium))
                                    .foregroundStyle(GardenTheme.secondaryText)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(GardenTheme.ink.opacity(0.035))
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                            HStack(spacing: 8) {
                                ForEach(durations, id: \.self) { minutes in
                                    Button("\(minutes) min") {
                                        model.settings.startSession(minutes: minutes)
                                    }
                                    .buttonStyle(MenuBarDurationButtonStyle())
                                }
                            }
                        }
                        .padding(10)
                    }
                }
            }
            .frame(width: 312)
            .background(GardenTheme.warmWhite)
            .tint(GardenTheme.moss)
            .handlesZenGardenCommands()
        }
    }

    private func openDashboard() {
        openWindow(id: "main")
        WindowController.showMainWindow()
    }

    private func headerStatus(state: FocusState, blockedCount: Int) -> String {
        if model.browserBlocker.permissionHelpNeeded {
            return "Browser access needed"
        }
        return state.isActive ? blockedSiteLabel(blockedCount) : "Not blocking"
    }

    private func sourceLabel(_ source: FocusSource?) -> String {
        switch source {
        case .manual:
            return "Manual session"
        case .daily:
            return "Daily schedule"
        case .schedule(let name):
            return name
        case nil:
            return ""
        }
    }

    private func remainingClock(until endDate: Date?, now: Date) -> String {
        guard let endDate else { return "In progress" }
        let total = max(0, Int(endDate.timeIntervalSince(now)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private func blockedSiteLabel(_ count: Int) -> String {
        "\(count) \(count == 1 ? "website" : "websites") blocked"
    }

    private func menuRemaining(until endDate: Date?, now: Date) -> String {
        guard let endDate else { return "Focus active" }
        let total = max(0, Int(endDate.timeIntervalSince(now)))
        let minutes = max(1, Int(ceil(Double(total) / 60)))
        return "\(minutes) min"
    }
}

private struct MenuBarPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(11, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(configuration.isPressed ? GardenTheme.mossPressed : GardenTheme.moss)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct MenuBarSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(11, weight: .semibold))
            .foregroundStyle(GardenTheme.matchaShadow)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(configuration.isPressed ? GardenTheme.matchaPale.opacity(0.34) : GardenTheme.matchaPale.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GardenTheme.matchaShadow.opacity(0.09), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct MenuBarWarningButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(10, weight: .medium))
            .foregroundStyle(GardenTheme.vermilion)
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(GardenTheme.vermilion.opacity(configuration.isPressed ? 0.12 : 0.065))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct MenuBarDurationButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GardenTypography.body(11, weight: .semibold))
            .foregroundStyle(GardenTheme.matchaShadow)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(configuration.isPressed ? GardenTheme.matchaPale.opacity(0.34) : GardenTheme.matchaPale.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GardenTheme.matchaShadow.opacity(0.09), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
