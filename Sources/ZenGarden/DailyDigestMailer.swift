import AppKit
import Foundation

enum DailyDigestMailError: LocalizedError {
    case mailUnavailable
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .mailUnavailable:
            "Apple Mail could not be found on this Mac."
        case .scriptFailed(let message):
            message.isEmpty ? "Apple Mail could not send the digest." : message
        }
    }
}

actor DailyDigestMailer {
    func send(to address: String, subject: String, body: String) throws {
        guard FileManager.default.fileExists(atPath: "/System/Applications/Mail.app") else {
            throw DailyDigestMailError.mailUnavailable
        }

        let script = """
        tell application "Mail"
            set digestMessage to make new outgoing message with properties {subject:\(appleScriptLiteral(subject)), content:\(appleScriptLiteral(body + "\n")), visible:false}
            tell digestMessage
                make new to recipient at end of to recipients with properties {address:\(appleScriptLiteral(address))}
                send
            end tell
        end tell
        """

        var errorInfo: NSDictionary?
        guard let mailScript = NSAppleScript(source: script) else {
            throw DailyDigestMailError.scriptFailed("Zen Garden could not prepare the Mail message.")
        }
        mailScript.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw DailyDigestMailError.scriptFailed(message)
        }
    }

    private func appleScriptLiteral(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        return lines
            .map { line in
                let escaped = line
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                return "\"\(escaped)\""
            }
            .joined(separator: " & linefeed & ")
    }
}
