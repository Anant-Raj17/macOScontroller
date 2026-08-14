import Foundation

@MainActor
final class ProfileStore: ObservableObject {
    @Published var profile: Profile {
        didSet { save() }
    }

    private let url: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let directory = support.appendingPathComponent("PadControl", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("profile.json")
        profile = Self.load(from: url) ?? .default
    }

    func resetToDefaults() {
        profile = .default
    }

    func setAction(_ action: Action, for input: ControlInput) {
        var next = profile
        if action == .unbound {
            next.bindings.removeValue(forKey: input)
        } else {
            next.bindings[input] = action
        }
        profile = next
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(profile)
            try data.write(to: url, options: [.atomic])
        } catch {
            NSLog("PadControl: failed to save profile: \(error.localizedDescription)")
        }
    }

    private static func load(from url: URL) -> Profile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data)
    }
}
