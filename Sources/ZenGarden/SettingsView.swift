import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var launchAtLogin = LoginItemController.isEnabled
    @State private var launchError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                PageHeader(
                    eyebrow: "",
                    title: "Settings",
                    subtitle: ""
                )

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "switch.2", title: "Mac behavior")

                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open Zen Garden when I log in")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Required for automatic schedules after login.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.68))
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(GardenTheme.moss)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            try LoginItemController.setEnabled(enabled)
                            launchError = nil
                        } catch {
                            launchError = error.localizedDescription
                            launchAtLogin = LoginItemController.isEnabled
                        }
                    }

                    if let launchError {
                        Text(launchError)
                            .font(GardenTypography.body(11))
                            .foregroundStyle(GardenTheme.vermilion)
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "sun.horizon", title: "Daily blocking")

                    Toggle(
                        isOn: Binding(
                            get: { model.settings.dailyFocusEnabled },
                            set: { model.settings.setDailyFocusEnabled($0) }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Block my distracting websites every day")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Uses the start and end times below.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.68))
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(GardenTheme.moss)

                    HStack(spacing: 28) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Starts")
                                .font(GardenTypography.body(13, weight: .semibold))
                            Text("Default: 7:00 AM")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.64))
                        }
                        Spacer()
                        DatePicker(
                            "Start time",
                            selection: Binding(
                                get: { date(for: model.settings.dailyStartMinute) },
                                set: { model.settings.setDailyStartMinute(minutes(from: $0)) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.field)

                        Divider()
                            .frame(height: 34)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Ends")
                                .font(GardenTypography.body(13, weight: .semibold))
                            Text("Default: 5:00 PM")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.64))
                        }
                        Spacer()
                        DatePicker(
                            "End time",
                            selection: Binding(
                                get: { date(for: model.settings.dailyCutoffMinute) },
                                set: {
                                    model.settings.setDailyCutoffMinute(minutes(from: $0))
                                    model.refreshDigestStatus()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.field)
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "envelope", title: "Daily email")

                    Toggle(
                        isOn: Binding(
                            get: { model.settings.digestEnabled },
                            set: {
                                model.settings.setDigestEnabled($0)
                                model.refreshDigestStatus()
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Email my break reasons at the cutoff")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Uses Apple Mail. Missed emails send after the Mac wakes.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.68))
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(GardenTheme.moss)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("SEND TO")
                            .font(GardenTypography.label(9, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(GardenTheme.softInk.opacity(0.66))
                        TextField(
                            "you@example.com",
                            text: Binding(
                                get: { model.settings.digestEmail },
                                set: {
                                    model.settings.setDigestEmail($0)
                                    model.refreshDigestStatus()
                                }
                            )
                        )
                        .textFieldStyle(.plain)
                        .font(GardenTypography.body(14))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(GardenTheme.ink.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }

                    HStack {
                        Text(model.digestStatus)
                            .font(GardenTypography.body(11))
                            .foregroundStyle(GardenTheme.softInk.opacity(0.72))
                            .lineLimit(2)
                        Spacer()
                        Button(model.isSendingDigest ? "Sending…" : "Send today now") {
                            Task { await model.sendTodayDigest() }
                        }
                        .buttonStyle(SoftButtonStyle())
                        .disabled(model.isSendingDigest || model.settings.digestEmail.isEmpty)
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        settingHeader(symbol: "lock.shield", title: "Browser permission")
                        Spacer()
                        Button(model.browserBlocker.isCheckingConnections ? "Checking…" : "Check browsers") {
                            Task {
                                await model.browserBlocker.checkInstalledBrowserConnections()
                            }
                        }
                        .buttonStyle(SoftButtonStyle())
                        .disabled(model.browserBlocker.isCheckingConnections)

                        Button("Open Automation settings") {
                            model.browserBlocker.openAutomationSettings()
                        }
                        .buttonStyle(SoftButtonStyle())
                    }

                    Text("macOS requires Automation access to redirect browser tabs and send email through Apple Mail. Manage access in Privacy & Security → Automation.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 9) {
                        ForEach(SupportedBrowser.all) { browser in
                            let connection = model.browserBlocker.connectionStatus(for: browser)
                            HStack {
                                Circle()
                                    .fill(connectionColor(connection))
                                    .frame(width: 7, height: 7)
                                Text(browser.name)
                                    .font(GardenTypography.body(13, weight: .medium))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(connection.label)
                                        .font(GardenTypography.body(11))
                                        .foregroundStyle(GardenTheme.softInk.opacity(0.62))
                                    if case .failed(let message) = connection {
                                        Text(message)
                                            .font(GardenTypography.body(9))
                                            .foregroundStyle(GardenTheme.vermilion.opacity(0.82))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 15) {
                    settingHeader(symbol: "leaf", title: "Privacy")
                    Text("No account or analytics. Blocked sites, access reasons, and schedules are stored locally. Access reasons are shared only with Apple Mail when an email is sent.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .zenCard()

                Text("Zen Garden · local development build 0.2.1")
                    .font(GardenTypography.body(10))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
            .padding(34)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            launchAtLogin = LoginItemController.isEnabled
        }
    }

    private func settingHeader(symbol: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(GardenTheme.vermilion)
            Text(title)
                .font(GardenTypography.body(15, weight: .semibold))
        }
    }

    private func date(for minute: Int) -> Date {
        let start = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func connectionColor(_ status: BrowserConnectionStatus) -> Color {
        switch status {
        case .ready:
            GardenTheme.moss
        case .permissionDenied, .failed:
            GardenTheme.vermilion
        case .notInstalled, .notRunning, .noWindow:
            GardenTheme.rakeLine.opacity(0.45)
        }
    }
}
