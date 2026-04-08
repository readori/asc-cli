import Foundation
import Mockable

/// Provides HTML template strings by name.
///
/// Templates are named HTML files with `{{placeholder}}` syntax,
/// loaded from bundle resources or disk. Plugins can register
/// custom template repositories to override the built-in templates.
@Mockable
public protocol HTMLTemplateRepository: Sendable {
    /// Load a template by name (e.g. "screen", "device", "wireframe").
    func template(named name: String) -> String?
}
