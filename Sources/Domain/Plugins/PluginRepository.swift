import Mockable

/// Manages the lifecycle of installed plugins in `~/.asc/plugins/`.
@Mockable
public protocol PluginRepository: Sendable {
    func listPlugins() async throws -> [Plugin]
    func getPlugin(name: String) async throws -> Plugin
    func installPlugin(from path: String) async throws -> Plugin
    func uninstallPlugin(name: String) async throws
    func enablePlugin(name: String) async throws -> Plugin
    func disablePlugin(name: String) async throws -> Plugin
}
