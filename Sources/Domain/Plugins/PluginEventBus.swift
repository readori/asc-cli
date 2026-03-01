import Mockable

/// Routes events to all enabled plugins that subscribe to them.
@Mockable
public protocol PluginEventBus: Sendable {
    func emit(event: PluginEvent, payload: PluginEventPayload) async throws
}
