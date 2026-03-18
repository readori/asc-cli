import Foundation
import PackagePlugin

@main
struct EmbedServerJS: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let input = context.package.directoryURL.appendingPathComponent("apps/server.js")
        let output = context.pluginWorkDirectoryURL.appendingPathComponent("EmbeddedServerJS.swift")

        return [
            .prebuildCommand(
                displayName: "Embed apps/server.js into Swift",
                executable: URL(fileURLWithPath: "/bin/bash"),
                arguments: [
                    "-c",
                    """
                    INPUT="\(input.path)"
                    OUTPUT="\(output.path)"
                    echo '// Auto-generated from apps/server.js — do not edit' > "$OUTPUT"
                    echo 'enum EmbeddedServerJS {' >> "$OUTPUT"
                    echo '    static let content: String = ###\"\"\"' >> "$OUTPUT"
                    cat "$INPUT" >> "$OUTPUT"
                    echo '\"\"\"###' >> "$OUTPUT"
                    echo '}' >> "$OUTPUT"
                    """,
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL
            ),
        ]
    }
}
