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
        case arc
    }

    static let all: [SupportedBrowser] = [
        SupportedBrowser(name: "Safari", bundleIdentifier: "com.apple.Safari", scriptingStyle: .safari),
        SupportedBrowser(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", scriptingStyle: .chromium),
        SupportedBrowser(name: "Brave", bundleIdentifier: "com.brave.Browser", scriptingStyle: .chromium),
        SupportedBrowser(name: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", scriptingStyle: .chromium),
        SupportedBrowser(name: "Arc", bundleIdentifier: "company.thebrowser.Browser", scriptingStyle: .arc),
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

enum BrowserConnectionStatus: Equatable, Sendable {
    case notInstalled
    case notRunning
    case noWindow
    case ready
    case permissionDenied
    case failed(String)

    var label: String {
        switch self {
        case .notInstalled: "Not installed"
        case .notRunning: "Installed · not open"
        case .noWindow: "Open · no window"
        case .ready: "Connected"
        case .permissionDenied: "Access needed"
        case .failed: "Connection failed"
        }
    }
}

actor BrowserScriptClient {
    static let notRunningMarker = "__ZEN_GARDEN_NOT_RUNNING__"
    static let noWindowMarker = "__ZEN_GARDEN_NO_WINDOW__"

    func currentURL(in browser: SupportedBrowser) -> ScriptResult {
        let tabExpression = tabExpression(for: browser)

        let script = """
        tell application id "\(browser.bundleIdentifier)"
            if it is not running then
                return "\(Self.notRunningMarker)"
            end if
            if (count of windows) is 0 then
                return "\(Self.noWindowMarker)"
            end if
            return \(tabExpression)
        end tell
        """

        return execute(script)
    }

    func redirect(browser: SupportedBrowser, to destination: String) -> ScriptResult {
        let escapedDestination = appleScriptString(destination)
        let tabExpression = tabExpression(for: browser)

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

    private func tabExpression(for browser: SupportedBrowser) -> String {
        browser.scriptingStyle == .safari
            ? "URL of current tab of front window"
            : "URL of active tab of front window"
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
    @Published private(set) var statusText = "Focus is off"
    @Published private(set) var detailText = "Websites are not being blocked."
    @Published private(set) var lastBlockedDomain: String?
    @Published private(set) var permissionHelpNeeded = false
    @Published private(set) var connectionStatuses: [String: BrowserConnectionStatus] = [:]
    @Published private(set) var isCheckingConnections = false

    private let scripts = BrowserScriptClient()
    private weak var settings: SettingsStore?
    private var timer: Timer?
    private var isChecking = false

    func start(settings: SettingsStore) {
        self.settings = settings
        guard timer == nil else { return }

        let pollingTimer = Timer(timeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkActiveBrowser()
            }
        }
        pollingTimer.tolerance = 0.12
        RunLoop.main.add(pollingTimer, forMode: .common)
        timer = pollingTimer

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

    func connectionStatus(for browser: SupportedBrowser) -> BrowserConnectionStatus {
        if let status = connectionStatuses[browser.bundleIdentifier] {
            return status
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) == nil
            ? .notInstalled
            : .notRunning
    }

    func checkInstalledBrowserConnections() async {
        guard !isCheckingConnections else { return }
        isCheckingConnections = true
        defer { isCheckingConnections = false }

        for browser in SupportedBrowser.all {
            guard NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: browser.bundleIdentifier
            ) != nil else {
                connectionStatuses[browser.bundleIdentifier] = .notInstalled
                continue
            }

            let result = await scripts.currentURL(in: browser)
            connectionStatuses[browser.bundleIdentifier] = status(for: result)
        }
        permissionHelpNeeded = connectionStatuses.values.contains(.permissionDenied)
    }

    private func checkActiveBrowser() async {
        guard !isChecking, let settings else { return }
        isChecking = true
        defer { isChecking = false }

        let now = Date()
        let focus = settings.focusState(at: now)
        guard focus.isActive else {
            statusText = "Focus is off"
            detailText = "Websites are not being blocked."
            return
        }

        guard let browser = SupportedBrowser.browser(
            for: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        ) else {
            statusText = "Focus is active"
            detailText = "Blocked websites will be redirected."
            return
        }

        statusText = "Monitoring \(browser.name)"
        detailText = "Blocked websites will be redirected."

        let current = await scripts.currentURL(in: browser)
        let currentStatus = status(for: current)
        connectionStatuses[browser.bundleIdentifier] = currentStatus

        if currentStatus == .permissionDenied {
            showPermissionError(for: browser)
            return
        }

        if case .failed(let message) = currentStatus {
            statusText = "\(browser.name) connection failed"
            detailText = message
            return
        }

        if currentStatus == .noWindow || currentStatus == .notRunning {
            statusText = "Focus is active"
            detailText = "\(browser.name) has no open browsing window."
            return
        }

        permissionHelpNeeded = false
        guard let urlString = current.value,
              !urlString.isEmpty,
              urlString != BrowserScriptClient.notRunningMarker,
              urlString != BrowserScriptClient.noWindowMarker,
              !urlString.hasPrefix("file://"),
              !urlString.hasPrefix("data:text/html"),
              !urlString.hasPrefix("about:blank#zen-garden-"),
              let match = DomainMatcher.firstMatch(
                  urlString: urlString,
                  in: settings.websitesForBlocking(at: now)
              )
        else { return }

        if !settings.isDomainLocked(match.domain, at: now),
           settings.isDomainTemporarilyAllowed(match.domain, at: now) {
            statusText = "Website temporarily unblocked"
            detailText = "\(match.domain) is temporarily unblocked."
            return
        }

        let outcome = await enforceBlock(domain: match.domain, in: browser)
        switch outcome {
        case .blocked(let usedFallback):
            connectionStatuses[browser.bundleIdentifier] = .ready
            permissionHelpNeeded = false
            detailText = usedFallback
                ? "\(match.domain) was blocked using the compatibility page."
                : "\(match.domain) was blocked."
        case .permissionDenied:
            connectionStatuses[browser.bundleIdentifier] = .permissionDenied
            showPermissionError(for: browser)
            return
        case .failed(let message):
            connectionStatuses[browser.bundleIdentifier] = .failed(message)
            statusText = "\(browser.name) could not block this page"
            detailText = message
            return
        }

        lastBlockedDomain = match.domain
        statusText = "Blocked \(match.domain)"
    }

    private enum EnforcementOutcome {
        case blocked(usedFallback: Bool)
        case permissionDenied
        case failed(String)
    }

    private func enforceBlock(
        domain: String,
        in browser: SupportedBrowser
    ) async -> EnforcementOutcome {
        guard let destination = blockedPageDestination(for: domain, browser: browser) else {
            return .failed("Zen Garden could not prepare its local focus page.")
        }

        let redirected = await scripts.redirect(browser: browser, to: destination)
        if redirected.errorCode == -1743 {
            return .permissionDenied
        }
        if let error = redirected.errorMessage {
            return .failed(error)
        }

        if await browserMovedAway(from: domain, in: browser) {
            return .blocked(usedFallback: false)
        }

        let fallback = BlockPageDestination.fallbackPage(domain: domain)
        let fallbackResult = await scripts.redirect(browser: browser, to: fallback)
        if fallbackResult.errorCode == -1743 {
            return .permissionDenied
        }
        if let error = fallbackResult.errorMessage {
            return .failed(error)
        }

        if await browserMovedAway(from: domain, in: browser) {
            return .blocked(usedFallback: true)
        }
        return .failed("\(browser.name) accepted the command but kept the blocked page open.")
    }

    private func browserMovedAway(
        from domain: String,
        in browser: SupportedBrowser
    ) async -> Bool {
        for _ in 0..<3 {
            try? await Task.sleep(nanoseconds: 120_000_000)
            let verification = await scripts.currentURL(in: browser)
            if verification.errorCode != nil {
                return false
            }
            guard let value = verification.value, !value.isEmpty else {
                continue
            }
            if value == BrowserScriptClient.notRunningMarker
                || value == BrowserScriptClient.noWindowMarker {
                return false
            }
            if !DomainMatcher.matches(urlString: value, blockedDomain: domain) {
                return true
            }
        }
        return false
    }

    private func status(for result: ScriptResult) -> BrowserConnectionStatus {
        if result.errorCode == -1743 {
            return .permissionDenied
        }
        if result.errorCode != nil {
            return .failed(result.errorMessage ?? "The browser returned an unknown automation error.")
        }
        if let message = result.errorMessage {
            return .failed(message)
        }
        switch result.value {
        case BrowserScriptClient.notRunningMarker:
            return .notRunning
        case BrowserScriptClient.noWindowMarker, "":
            return .noWindow
        default:
            return .ready
        }
    }

    private func showPermissionError(for browser: SupportedBrowser) {
        permissionHelpNeeded = true
        statusText = "Browser access needed"
        detailText = "Allow Zen Garden to control \(browser.name) in System Settings."
    }

    private func blockedPageDestination(for domain: String, browser: SupportedBrowser) -> String? {
        guard let resource = AppResources.url(forResource: "Blocked", withExtension: "html") else {
            return nil
        }

        if browser.scriptingStyle != .safari,
           let html = try? String(contentsOf: resource, encoding: .utf8) {
            return BlockPageDestination.inlinePage(
                html: embeddedBlockPageResources(in: html),
                domain: domain
            )
        }

        return "\(resource.absoluteString)#\(domain)"
    }

    private func embeddedBlockPageResources(in html: String) -> String {
        var embeddedHTML = html

        if let artworkURL = AppResources.url(
            forResource: "ZenGardenHeroBrowser",
            withExtension: "jpg"
        ),
        let artworkData = try? Data(contentsOf: artworkURL) {
            let dataURL = "data:image/jpeg;base64,\(artworkData.base64EncodedString())"
            embeddedHTML = embeddedHTML.replacingOccurrences(
                of: "ZenGardenHeroBrowser.jpg",
                with: dataURL
            )
        }

        if let fontURL = AppResources.url(
            forResource: "InterVariable",
            withExtension: "woff2"
        ),
        let fontData = try? Data(contentsOf: fontURL) {
            let dataURL = "data:font/woff2;base64,\(fontData.base64EncodedString())"
            embeddedHTML = embeddedHTML.replacingOccurrences(
                of: "InterVariable.woff2",
                with: dataURL
            )
        }

        return embeddedHTML
    }
}
