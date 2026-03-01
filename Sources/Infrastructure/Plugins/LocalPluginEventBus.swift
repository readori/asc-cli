import Domain
import Foundation

/// Routes events to all enabled plugins subscribed to them.
///
/// All matching plugins run concurrently via `TaskGroup`.
/// Individual plugin failures are printed to stderr but do not
/// propagate — one failing plugin must not block others.
public struct LocalPluginEventBus: PluginEventBus {

    private let pluginRepository: any PluginRepository
    private let pluginRunner: any PluginRunner

    public init(
        pluginRepository: any PluginRepository,
        pluginRunner: any PluginRunner
    ) {
        self.pluginRepository = pluginRepository
        self.pluginRunner = pluginRunner
    }

    public func emit(event: PluginEvent, payload: PluginEventPayload) async throws {
        let plugins = try await pluginRepository.listPlugins()
        let subscribed = plugins.filter { $0.isEnabled && $0.subscribedEvents.contains(event) }

        await withTaskGroup(of: Void.self) { group in
            for plugin in subscribed {
                group.addTask {
                    do {
                        let result = try await pluginRunner.run(plugin: plugin, event: event, payload: payload)
                        if let msg = result.message {
                            fputs("[plugin:\(plugin.name)] \(msg)\n", stderr)
                        }
                    } catch {
                        fputs("[plugin:\(plugin.name)] error: \(error.localizedDescription)\n", stderr)
                    }
                }
            }
        }
    }
}
