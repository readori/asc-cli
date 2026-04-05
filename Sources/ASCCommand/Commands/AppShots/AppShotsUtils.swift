import ArgumentParser
import Domain
import Foundation

/// Resolves the Gemini API key from CLI argument, environment variable, or saved config.
func resolveGeminiApiKey(_ cliArgument: String?, configStorage: any AppShotsConfigStorage) throws -> String {
    if let key = cliArgument, !key.isEmpty { return key }
    if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty { return key }
    if let config = try configStorage.load(), !config.geminiApiKey.isEmpty { return config.geminiApiKey }
    throw ValidationError(
        "Gemini API key required. Use --gemini-api-key, set GEMINI_API_KEY env var, or run:\n  asc app-shots config --gemini-api-key KEY"
    )
}

