import AppKit
import Combine
import Foundation

struct SupportedBrowser: Identifiable, Equatable, Sendable {
    let name: String
    let bundleIdentifier: String
    let scriptingStyle: ScriptingStyle

    var id: String { bundleIdentifier }

    enum ScriptingStyle: Sendable {
        case safari
        case chromium
    }

    static let all: [SupportedBrowser] = [
        SupportedBrowser(name: "Safari", bundleIdentifier: "com.apple.Safari", scriptingStyle: .safari),
        SupportedBrowser(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", scriptingStyle: .chromium),
        SupportedBrowser(name: "Brave", bundleIdentifier: "com.brave.Browser", scriptingStyle: .chromium),
        SupportedBrowser(name: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", scriptingStyle: .chromium),
        SupportedBrowser(name: "Arc", bundleIdentifier: "company.thebrowser.Browser", scriptingStyle: .chromium),
        SupportedBrowser(name: "Opera", bundleIdentifier: "com.operasoftware.Opera", scriptingStyle: .chromium)
    ]

    static func browser(for bundleIdentifier: String?) -> SupportedBrowser? {
        guard let bundleIdentifier else { return nil }
        return all.first { $0.bundleIdentifier == bundleIdentifier }
    }
}

struct ScriptResult: Sendable {
    var value: String?
    var errorCode: Int?
    var errorMessage: String?
}

actor BrowserScriptClient {
    func currentURL(in browser: SupportedBrowser) -> ScriptResult {
        let tabExpression = browser.scriptingStyle == .safari
            ? "URL of current tab of front window"
            : "URL of active tab of front window"

        let script = """
        tell application id "\(browser.bundleIdentifier)"
            if it is running then
                if (count of windows) > 0 then
                    return \(tabExpression)
                end if
            end if
        end tell
        return ""
        """

        return execute(script)
    }

    func redirect(browser: SupportedBrowser, to destination: URL) -> ScriptResult {
        let escapedDestination = appleScriptString(destination.absoluteString)
        let tabExpression = browser.scriptingStyle == .safari
            ? "URL of current tab of front window"
            : "URL of active tab of front window"

        let script = """
        tell application id "\(browser.bundleIdentifier)"
            if it is running then
                if (count of windows) > 0 then
                    set \(tabExpression) to "\(escapedDestination)"
                    return "ok"
                end if
            end if
        end tell
        return ""
        """

        return execute(script)
    }

    private func execute(_ source: String) -> ScriptResult {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return ScriptResult(value: nil, errorCode: nil, errorMessage: "Could not prepare browser automation.")
        }

        let descriptor = script.executeAndReturnError(&errorInfo)
        let code = errorInfo?[NSAppleScript.errorNumber] as? Int
        let message = errorInfo?[NSAppleScript.errorMessage] as? String
        return ScriptResult(value: descriptor.stringValue, errorCode: code, errorMessage: message)
    }

    private func appleScriptString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

@MainActor
final class BrowserBlocker: ObservableObject {
    @Published private(set) var statusText = "Resting"
    @Published private(set) var detailText = "Begin a focus session when you are ready."
    @Published private(set) var lastBlockedDomain: String?
    @Published private(set) var permissionHelpNeeded = false

    private let scripts = BrowserScriptClient()
    private weak var settings: SettingsStore?
    private var timer: Timer?
    private var isChecking = false
    private var lastRedirect: (domain: String, date: Date)?

    func start(settings: SettingsStore) {
        self.settings = settings
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkActiveBrowser()
            }
        }
        timer?.tolerance = 0.12

        Task {
            await checkActiveBrowser()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else { return }
        NSWorkspace.shared.open(url)
    }

    private func checkActiveBrowser() async {
        guard !isChecking, let settings else { return }
        isChecking = true
        defer { isChecking = false }

        let focus = settings.focusState()
        guard focus.isActive else {
            statusText = "Resting"
            detailText = "Begin a focus session when you are ready."
            return
        }

        guard let browser = SupportedBrowser.browser(
            for: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        ) else {
            statusText = "Focus is active"
            detailText = "Waiting quietly in the background."
            return
        }

        statusText = "Watching \(browser.name)"
        detailText = "Distracting paths are closed during this session."

        let current = await scripts.currentURL(in: browser)
        if current.errorCode == -1743 {
            permissionHelpNeeded = true
            statusText = "Automation permission needed"
            detailText = "Allow Zen Garden to control \(browser.name) in System Settings."
            return
        }

        guard let urlString = current.value,
              !urlString.isEmpty,
              !urlString.hasPrefix("file://"),
              let match = DomainMatcher.firstMatch(urlString: urlString, in: settings.websites)
        else { return }

        if let lastRedirect,
           lastRedirect.domain == match.domain,
           Date().timeIntervalSince(lastRedirect.date) < 1.5 {
            return
        }

        guard let destination = blockedPageURL(for: match.domain) else {
            statusText = "Could not load the focus page"
            return
        }

        let redirected = await scripts.redirect(browser: browser, to: destination)
        if redirected.errorCode == -1743 {
            permissionHelpNeeded = true
            statusText = "Automation permission needed"
            detailText = "Allow Zen Garden to control \(browser.name) in System Settings."
            return
        }

        guard redirected.errorCode == nil else {
            statusText = "Browser connection interrupted"
            detailText = redirected.errorMessage ?? "Return to Zen Garden and try again."
            return
        }

        lastRedirect = (match.domain, Date())
        lastBlockedDomain = match.domain
        statusText = "A distraction was released"
        detailText = "\(match.domain) is closed until focus ends."
    }

    private func blockedPageURL(for domain: String) -> URL? {
        guard let resource = Bundle.module.url(forResource: "Blocked", withExtension: "html") else {
            return nil
        }

        var components = URLComponents(url: resource, resolvingAgainstBaseURL: false)
        components?.fragment = domain
        return components?.url
    }
}
