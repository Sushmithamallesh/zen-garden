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
                    eyebrow: "Care",
                    title: "A small, private tool",
                    subtitle: "Zen Garden runs locally and asks only for the browser access required to redirect blocked pages."
                )

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "switch.2", title: "Mac behavior")

                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open Zen Garden when I log in")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Recommended for automatic work-hour schedules.")
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
                    settingHeader(symbol: "sun.horizon", title: "Daily boundary")

                    Toggle(
                        isOn: Binding(
                            get: { model.settings.dailyFocusEnabled },
                            set: { model.settings.setDailyFocusEnabled($0) }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Block my distracting websites every day")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("The boundary begins automatically at midnight and stays active until the cutoff.")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.68))
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(GardenTheme.moss)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Daily cutoff")
                                .font(GardenTypography.body(13, weight: .semibold))
                            Text("Default: 5:00 PM")
                                .font(GardenTypography.body(11))
                                .foregroundStyle(GardenTheme.softInk.opacity(0.64))
                        }
                        Spacer()
                        DatePicker(
                            "Daily cutoff",
                            selection: Binding(
                                get: { date(for: model.settings.dailyCutoffMinute) },
                                set: { model.settings.setDailyCutoffMinute(minutes(from: $0)) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.field)
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 18) {
                    settingHeader(symbol: "envelope", title: "Daily reflection")

                    Toggle(
                        isOn: Binding(
                            get: { model.settings.digestEnabled },
                            set: { model.settings.setDigestEnabled($0) }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Email my break reasons at the cutoff")
                                .font(GardenTypography.body(14, weight: .semibold))
                            Text("Sent through your Apple Mail account. If your Mac is asleep, it sends after wake.")
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
                                set: { model.settings.setDigestEmail($0) }
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
                        Button("Open Automation settings") {
                            model.browserBlocker.openAutomationSettings()
                        }
                        .buttonStyle(SoftButtonStyle())
                    }

                    Text("The first time Zen Garden blocks a page or sends a reflection, macOS asks whether it may control that app. Choose Allow. You can review this later in Privacy & Security → Automation.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 9) {
                        ForEach(SupportedBrowser.all) { browser in
                            HStack {
                                Circle()
                                    .fill(GardenTheme.rakeLine.opacity(0.35))
                                    .frame(width: 7, height: 7)
                                Text(browser.name)
                                    .font(GardenTypography.body(13, weight: .medium))
                                Spacer()
                                Text(NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) == nil ? "Not installed" : "Supported")
                                    .font(GardenTypography.body(11))
                                    .foregroundStyle(GardenTheme.softInk.opacity(0.62))
                            }
                        }
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 15) {
                    settingHeader(symbol: "leaf", title: "Privacy")
                    Text("No account, analytics, browsing history, or Zen Garden server is used. Your blocklist, break reasons, and schedules stay in your macOS user preferences. Break reasons leave your Mac only when Apple Mail sends your daily reflection.")
                        .font(GardenTypography.body(13))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .zenCard()

                Text("Zen Garden · local development build 0.2.0")
                    .font(GardenTypography.body(10))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
            .padding(34)
        }
        .scrollIndicators(.hidden)
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
}
