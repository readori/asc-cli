import Mockable

@Mockable
public protocol SimulatorInteractionRepository: Sendable {
    func tap(udid: String, x: Int, y: Int) async throws
    func tapById(udid: String, identifier: String) async throws
    func tapByLabel(udid: String, label: String) async throws
    func swipe(udid: String, startX: Int, startY: Int, endX: Int, endY: Int, duration: Double?, delta: Int?) async throws
    func gesture(udid: String, gesture: SimulatorGesture) async throws
    func type(udid: String, text: String) async throws
    func key(udid: String, keyCode: Int, duration: Double?) async throws
    func keyCombo(udid: String, modifiers: [Int], key: Int) async throws
    func button(udid: String, button: SimulatorButton) async throws
    func describeUI(udid: String, point: String?) async throws -> String
    func batch(udid: String, steps: [String]) async throws
    func isAvailable() -> Bool
}
