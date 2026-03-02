import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("LocalPluginRepository")
struct LocalPluginRepositoryTests {

    // MARK: - Helpers

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-plugin-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Creates a valid plugin directory at `dir/<name>/` with manifest.json and run executable.
    private func writePlugin(
        in dir: URL,
        name: String,
        version: String = "1.0.0",
        description: String = "A test plugin",
        author: String? = "Test Author",
        events: [PluginEvent] = [.buildUploaded]
    ) throws {
        let pluginDir = dir.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true)

        var manifest: [String: Any] = [
            "name": name,
            "version": version,
            "description": description,
            "events": events.map(\.rawValue)
        ]
        if let author { manifest["author"] = author }
        let manifestData = try JSONSerialization.data(withJSONObject: manifest)
        try manifestData.write(to: pluginDir.appendingPathComponent("manifest.json"))

        let executableURL = pluginDir.appendingPathComponent("run")
        try "#!/bin/sh\necho '{\"success\":true}'".write(to: executableURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)
    }

    // MARK: - listPlugins

    @Test func `listPlugins returns empty when plugins directory does not exist`() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-nonexistent-\(UUID().uuidString)")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.isEmpty)
    }

    @Test func `listPlugins returns empty when directory has no plugin subdirectories`() async throws {
        let dir = try makeTempDir()
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.isEmpty)
    }

    @Test func `listPlugins returns plugin from valid directory`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "slack-notify", version: "2.1.0", description: "Slack notifier", author: "Dev")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.count == 1)
        #expect(plugins[0].name == "slack-notify")
        #expect(plugins[0].version == "2.1.0")
        #expect(plugins[0].description == "Slack notifier")
        #expect(plugins[0].author == "Dev")
        #expect(plugins[0].subscribedEvents == [.buildUploaded])
        #expect(plugins[0].isEnabled == true)
    }

    @Test func `listPlugins returns plugins sorted alphabetically by name`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "zebra-plugin")
        try writePlugin(in: dir, name: "alpha-plugin")
        try writePlugin(in: dir, name: "mango-plugin")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.map(\.name) == ["alpha-plugin", "mango-plugin", "zebra-plugin"])
    }

    @Test func `listPlugins skips directories missing manifest and loads valid ones`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "valid-plugin")
        // Create a directory without a manifest (simulates a corrupt install)
        let incompleteDir = dir.appendingPathComponent("broken-plugin")
        try FileManager.default.createDirectory(at: incompleteDir, withIntermediateDirectories: true)
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.count == 1)
        #expect(plugins[0].name == "valid-plugin")
    }

    @Test func `listPlugins reflects disabled state via dot-disabled marker file`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "disabled-plugin")
        let markerPath = dir.appendingPathComponent("disabled-plugin/.disabled").path
        FileManager.default.createFile(atPath: markerPath, contents: nil)
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.count == 1)
        #expect(plugins[0].isEnabled == false)
    }

    @Test func `listPlugins plugin without author omits author field`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "anonymous-plugin", author: nil)
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugins = try await repo.listPlugins()

        #expect(plugins.count == 1)
        #expect(plugins[0].author == nil)
    }

    // MARK: - getPlugin

    @Test func `getPlugin returns plugin model for known name`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "my-plugin", description: "My plugin description", events: [.versionSubmitted])
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugin = try await repo.getPlugin(name: "my-plugin")

        #expect(plugin.name == "my-plugin")
        #expect(plugin.description == "My plugin description")
        #expect(plugin.subscribedEvents == [.versionSubmitted])
    }

    @Test func `getPlugin throws notFound for unknown plugin name`() async throws {
        let dir = try makeTempDir()
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        await #expect(throws: PluginError.self) {
            _ = try await repo.getPlugin(name: "missing-plugin")
        }
    }

    // MARK: - installPlugin

    @Test func `installPlugin copies plugin to plugins directory and returns model`() async throws {
        let sourceParent = try makeTempDir()
        let destDir = try makeTempDir()
        try writePlugin(in: sourceParent, name: "new-plugin", version: "1.2.0")
        let sourcePath = sourceParent.appendingPathComponent("new-plugin").path
        let repo = LocalPluginRepository(pluginsDirectory: destDir)

        let plugin = try await repo.installPlugin(from: sourcePath)

        #expect(plugin.name == "new-plugin")
        #expect(plugin.version == "1.2.0")
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("new-plugin/manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("new-plugin/run").path))
    }

    @Test func `installPlugin sets executable bit on run file`() async throws {
        let sourceParent = try makeTempDir()
        let destDir = try makeTempDir()
        try writePlugin(in: sourceParent, name: "exec-plugin")
        let sourcePath = sourceParent.appendingPathComponent("exec-plugin").path
        let repo = LocalPluginRepository(pluginsDirectory: destDir)

        _ = try await repo.installPlugin(from: sourcePath)

        let attrs = try FileManager.default.attributesOfItem(atPath: destDir.appendingPathComponent("exec-plugin/run").path)
        let perms = attrs[.posixPermissions] as? Int
        #expect(perms == 0o755)
    }

    @Test func `installPlugin throws missingManifest when manifest is absent`() async throws {
        let sourceParent = try makeTempDir()
        // Directory has a run executable but no manifest
        let pluginDir = sourceParent.appendingPathComponent("no-manifest-plugin")
        try FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true)
        try "#!/bin/sh".write(to: pluginDir.appendingPathComponent("run"), atomically: true, encoding: .utf8)
        let repo = LocalPluginRepository(pluginsDirectory: try makeTempDir())

        await #expect(throws: PluginError.self) {
            _ = try await repo.installPlugin(from: pluginDir.path)
        }
    }

    @Test func `installPlugin throws missingExecutable when run is absent`() async throws {
        let sourceParent = try makeTempDir()
        let pluginDir = sourceParent.appendingPathComponent("no-exec-plugin")
        try FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true)
        let manifest: [String: Any] = ["name": "no-exec-plugin", "version": "1.0.0", "description": "test", "events": ["build.uploaded"]]
        try JSONSerialization.data(withJSONObject: manifest).write(to: pluginDir.appendingPathComponent("manifest.json"))
        let repo = LocalPluginRepository(pluginsDirectory: try makeTempDir())

        await #expect(throws: PluginError.self) {
            _ = try await repo.installPlugin(from: pluginDir.path)
        }
    }

    @Test func `installPlugin overwrites existing plugin with newer version`() async throws {
        let destDir = try makeTempDir()
        let source1Parent = try makeTempDir()
        try writePlugin(in: source1Parent, name: "replace-me", version: "1.0.0")
        let repo = LocalPluginRepository(pluginsDirectory: destDir)
        _ = try await repo.installPlugin(from: source1Parent.appendingPathComponent("replace-me").path)

        let source2Parent = try makeTempDir()
        try writePlugin(in: source2Parent, name: "replace-me", version: "2.0.0")
        let updated = try await repo.installPlugin(from: source2Parent.appendingPathComponent("replace-me").path)

        #expect(updated.version == "2.0.0")
    }

    // MARK: - uninstallPlugin

    @Test func `uninstallPlugin removes plugin directory from filesystem`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "to-remove")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        try await repo.uninstallPlugin(name: "to-remove")

        #expect(!FileManager.default.fileExists(atPath: dir.appendingPathComponent("to-remove").path))
    }

    @Test func `uninstallPlugin throws notFound for unknown plugin`() async throws {
        let dir = try makeTempDir()
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        await #expect(throws: PluginError.self) {
            try await repo.uninstallPlugin(name: "ghost-plugin")
        }
    }

    // MARK: - disablePlugin

    @Test func `disablePlugin creates dot-disabled marker and returns disabled plugin`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "active-plugin")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugin = try await repo.disablePlugin(name: "active-plugin")

        #expect(plugin.isEnabled == false)
        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("active-plugin/.disabled").path))
    }

    @Test func `disablePlugin is idempotent when already disabled`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "already-off")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        _ = try await repo.disablePlugin(name: "already-off")
        let plugin = try await repo.disablePlugin(name: "already-off")

        #expect(plugin.isEnabled == false)
    }

    @Test func `disablePlugin throws notFound for unknown plugin`() async throws {
        let dir = try makeTempDir()
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        await #expect(throws: PluginError.self) {
            _ = try await repo.disablePlugin(name: "nobody")
        }
    }

    // MARK: - enablePlugin

    @Test func `enablePlugin removes dot-disabled marker and returns enabled plugin`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "paused-plugin")
        let markerPath = dir.appendingPathComponent("paused-plugin/.disabled").path
        FileManager.default.createFile(atPath: markerPath, contents: nil)
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        let plugin = try await repo.enablePlugin(name: "paused-plugin")

        #expect(plugin.isEnabled == true)
        #expect(!FileManager.default.fileExists(atPath: markerPath))
    }

    @Test func `enablePlugin is idempotent when already enabled`() async throws {
        let dir = try makeTempDir()
        try writePlugin(in: dir, name: "already-on")
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        _ = try await repo.enablePlugin(name: "already-on")
        let plugin = try await repo.enablePlugin(name: "already-on")

        #expect(plugin.isEnabled == true)
    }

    @Test func `enablePlugin throws notFound for unknown plugin`() async throws {
        let dir = try makeTempDir()
        let repo = LocalPluginRepository(pluginsDirectory: dir)

        await #expect(throws: PluginError.self) {
            _ = try await repo.enablePlugin(name: "nobody")
        }
    }
}
