import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var launchAtLogin = LoginItemController.isEnabled
    @State private var launchError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .center) {
                    PageHeader(
                        eyebrow: "",
                        title: "Settings",
                        subtitle: ""
                    )

                    Spacer()

                    Button("Done") { dismiss() }
                        .buttonStyle(GardenPrimaryButtonStyle(compact: true))
                        .keyboardShortcut(.cancelAction)
                }

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "switch.2", title: "Startup")

                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open at login")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Keeps automatic blocking running after you restart your Mac.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.secondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(GardenTheme.moss)
                            .accessibilityLabel("Open Zen Garden at login")
                    }
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "sun.horizon", title: "Automatic blocking")

                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Block on weekdays")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Runs at these times Monday–Friday. Saturday is off; Sunday runs all day.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.secondaryText)
                        }

                        Spacer()

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { model.settings.dailyFocusEnabled },
                                set: { model.settings.setDailyFocusEnabled($0) }
                            )
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(GardenTheme.moss)
                        .accessibilityLabel("Block on weekdays")
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Starts")
                                .font(GardenTypography.body(13, weight: .semibold))

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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .frame(height: 48)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ends")
                                .font(GardenTypography.body(13, weight: .semibold))

                            DatePicker(
                                "End time",
                                selection: Binding(
                                    get: { date(for: model.settings.dailyCutoffMinute) },
                                    set: { model.settings.setDailyCutoffMinute(minutes(from: $0)) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.field)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        settingHeader(symbol: "lock.shield", title: "Browser access")
                        Spacer()
                        Button(model.browserBlocker.isCheckingConnections ? "Checking…" : "Check access") {
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

                    Text("Zen Garden uses Automation access to show its local block page. Manage it in Privacy & Security → Automation.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.secondaryText)
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
                                        .foregroundStyle(GardenTheme.secondaryText)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .zenCard()

                VStack(alignment: .leading, spacing: 15) {
                    settingHeader(symbol: "leaf", title: "Privacy")
                    Text("No account. No analytics. Blocked websites, schedules, and access reasons stay on this Mac.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .zenCard()

                Text(versionText)
                    .font(GardenTypography.body(10))
                    .foregroundStyle(GardenTheme.secondaryText)
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
                .foregroundStyle(GardenTheme.moss)
            Text(title)
                .font(GardenTypography.body(15, weight: .semibold))
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "Zen Garden \(version ?? "")"
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
            GardenTheme.softInk.opacity(0.48)
        }
    }
}
