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
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("Recommended for automatic work-hour schedules.")
                                .font(.system(size: 11, design: .rounded))
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
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(GardenTheme.vermilion)
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

                    Text("The first time Zen Garden needs to block a page, macOS asks whether it may control that browser. Choose Allow. You can review this later in Privacy & Security → Automation.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 9) {
                        ForEach(SupportedBrowser.all) { browser in
                            HStack {
                                Circle()
                                    .fill(GardenTheme.rakeLine.opacity(0.35))
                                    .frame(width: 7, height: 7)
                                Text(browser.name)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                Spacer()
                                Text(NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) == nil ? "Not installed" : "Supported")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(GardenTheme.softInk.opacity(0.62))
                            }
                        }
                    }
                }
                .zenCard()

                VStack(alignment: .leading, spacing: 15) {
                    settingHeader(symbol: "leaf", title: "Privacy")
                    Text("No account, analytics, browsing history, or network service is used. Zen Garden looks only at the active tab of a supported browser while focus is active. Your blocklist and schedules are stored in your macOS user preferences.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(GardenTheme.softInk.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .zenCard()

                Text("Zen Garden · local development build 0.1.1")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(GardenTheme.softInk.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
            .padding(34)
        }
    }

    private func settingHeader(symbol: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(GardenTheme.vermilion)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
    }
}
