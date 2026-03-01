import Mockable

/// Executes a plugin's `run` executable with an event payload.
@Mockable
public protocol PluginRunner: Sendable {
    func run(plugin: Plugin, event: PluginEvent, payload: PluginEventPayload) async throws -> PluginResult
}
