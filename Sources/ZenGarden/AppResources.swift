import AppKit
import Foundation

enum AppResources {
    private static let resourceBundleName = "ZenGarden_ZenGarden.bundle"

    static func url(forResource name: String, withExtension fileExtension: String) -> URL? {
        let filename = "\(name).\(fileExtension)"
        let candidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent(resourceBundleName, isDirectory: true)
                .appendingPathComponent(filename),
            Bundle.main.resourceURL?
                .appendingPathComponent(resourceBundleName, isDirectory: true)
                .appendingPathComponent("Contents/Resources", isDirectory: true)
                .appendingPathComponent(filename),
            Bundle.main.bundleURL
                .appendingPathComponent(resourceBundleName, isDirectory: true)
                .appendingPathComponent(filename),
            Bundle.main.resourceURL?.appendingPathComponent(filename),
            Bundle.main.bundleURL.appendingPathComponent(filename)
        ].compactMap { $0 }

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    @MainActor
    static func image(named name: String) -> NSImage? {
        guard let url = url(forResource: name, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }
}
