# Plugins

ASC supports a plugin system that lets you extend the CLI with custom event handlers. Plugins are any executable (Swift script, bash, Python, etc.) that follow a simple JSON stdin/stdout protocol. Examples: send Slack or Telegram notifications when a build is uploaded or a version is submitted.

## CLI Usage

### `asc plugins list`

List all installed plugins.

```
asc plugins list [--output json|table|markdown] [--pretty]
```

**Example:**
```bash
asc plugins list --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "disable": "asc plugins disable --name slack-notify",
        "listPlugins": "asc plugins list",
        "run.build.uploaded": "asc plugins run --name slack-notify --event build.uploaded",
        "run.version.submitted": "asc plugins run --name slack-notify --event version.submitted",
        "uninstall": "asc plugins uninstall --name slack-notify"
      },
      "author": "Your Name",
      "description": "Send Slack notifications for App Store events",
      "executablePath": "/Users/you/.asc/plugins/slack-notify/run",
      "id": "slack-notify",
      "isEnabled": true,
      "name": "slack-notify",
      "subscribedEvents": ["build.uploaded", "version.submitted"],
      "version": "1.0.0"
    }
  ]
}
```

**Table output:**
```
Name          Version  Enabled  Events
------------  -------  -------  ----------------------------------------
slack-notify  1.0.0    yes      build.uploaded, version.submitted
```

---

### `asc plugins install <path>`

Install a plugin from a local directory. The directory must contain:
- `manifest.json` — plugin metadata and event subscriptions
- `run` — executable file (any language, must be `chmod +x`)

```
asc plugins install <path> [--output json|table|markdown] [--pretty]
```

**Example:**
```bash
asc plugins install ./my-plugins/slack-notify
```

---

### `asc plugins uninstall`

Remove an installed plugin.

```
asc plugins uninstall --name <name>
```

**Example:**
```bash
asc plugins uninstall --name slack-notify
```

---

### `asc plugins enable`

Enable a previously disabled plugin.

```
asc plugins enable --name <name> [--output json|table|markdown] [--pretty]
```

---

### `asc plugins disable`

Disable a plugin without removing it.

```
asc plugins disable --name <name> [--output json|table|markdown] [--pretty]
```

---

### `asc plugins run`

Manually invoke a plugin for a given event — useful for testing your plugin.

| Flag | Description |
|------|-------------|
| `--name` | Plugin name (required) |
| `--event` | Event to fire: `build.uploaded`, `version.submitted`, `version.approved`, `version.rejected` (required) |
| `--app-id` | App ID to include in the event payload |
| `--version-id` | Version ID to include in the event payload |
| `--build-id` | Build ID to include in the event payload |

**Example:**
```bash
asc plugins run --name slack-notify --event build.uploaded --app-id 123456789 --build-id build-42
```

**JSON output:**
```json
[{"message": "Slack notification sent", "success": true}]
```

---

## Plugin Directory Layout

Plugins are stored in `~/.asc/plugins/`:

```
~/.asc/plugins/
└── slack-notify/
    ├── manifest.json    ← plugin metadata + event subscriptions
    ├── run              ← executable (any language, chmod +x)
    └── .disabled        ← optional marker file: present = disabled
```

## Plugin Protocol (stdin/stdout JSON)

When an event fires, ASC spawns the `run` executable and communicates via JSON:

**stdin → plugin:**
```json
{
  "event": "build.uploaded",
  "payload": {
    "event": "build.uploaded",
    "appId": "123456789",
    "buildId": "build-42",
    "timestamp": "2026-03-01T12:00:00Z",
    "metadata": {}
  }
}
```

**plugin → stdout:**
```json
{"success": true, "message": "Slack notification sent"}
```

Exit code 0 is required for success. If the plugin exits with a non-zero code, ASC prints an error to stderr and continues.

## `manifest.json` Format

```json
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Send Slack notifications for App Store events",
  "author": "Your Name",
  "events": ["build.uploaded", "version.submitted", "version.approved", "version.rejected"]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique plugin name (also the directory name) |
| `version` | Yes | Semver string |
| `description` | Yes | Human-readable description |
| `author` | No | Author name or email |
| `events` | Yes | Array of `PluginEvent` raw values to subscribe to |

## Supported Events

| Event | Fired by |
|-------|----------|
| `build.uploaded` | `asc builds upload` after a successful upload |
| `version.submitted` | `asc versions submit` after a successful submission |
| `version.approved` | Reserved for future use |
| `version.rejected` | Reserved for future use |

## Example Plugin: Slack Notification (bash)

```bash
#!/bin/bash
# ~/.asc/plugins/slack-notify/run

INPUT=$(cat)
EVENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['event'])")
APP_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['payload'].get('appId',''))")

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-type: application/json' \
  --data "{\"text\":\":rocket: ASC event: $EVENT for app $APP_ID\"}" > /dev/null

echo '{"success": true, "message": "Slack notification sent"}'
```

```json
// manifest.json
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Send Slack notifications for App Store events",
  "author": "Your Name",
  "events": ["build.uploaded", "version.submitted"]
}
```

**Install and test:**
```bash
chmod +x ~/.asc/plugins/slack-notify/run
asc plugins install ./slack-notify
asc plugins run --name slack-notify --event build.uploaded --app-id 123456789
```

## Typical Workflow

```bash
# 1. Create your plugin directory
mkdir ~/my-slack-plugin
cat > ~/my-slack-plugin/manifest.json <<'EOF'
{
  "name": "slack-notify",
  "version": "1.0.0",
  "description": "Slack notifications",
  "events": ["build.uploaded", "version.submitted"]
}
EOF

cat > ~/my-slack-plugin/run <<'EOF'
#!/bin/bash
INPUT=$(cat)
echo '{"success": true, "message": "Done"}'
EOF
chmod +x ~/my-slack-plugin/run

# 2. Install
asc plugins install ~/my-slack-plugin

# 3. Test manually
asc plugins run --name slack-notify --event build.uploaded --app-id 1234 --pretty

# 4. Upload a build — plugin fires automatically
asc builds upload --app-id 1234 --file MyApp.ipa --version 1.0 --build-number 42

# 5. List, disable, re-enable
asc plugins list
asc plugins disable --name slack-notify
asc plugins enable --name slack-notify

# 6. Uninstall when done
asc plugins uninstall --name slack-notify
```

## Architecture

```
ASCCommand Layer
  PluginsCommand
  ├── PluginsList         → pluginRepo.listPlugins()
  ├── PluginsInstall      → pluginRepo.installPlugin(from:)
  ├── PluginsUninstall    → pluginRepo.uninstallPlugin(name:)
  ├── PluginsEnable       → pluginRepo.enablePlugin(name:)
  ├── PluginsDisable      → pluginRepo.disablePlugin(name:)
  └── PluginsRun          → pluginRepo.getPlugin(name:) + pluginRunner.run(...)
  VersionsSubmit          → eventBus.emit(.versionSubmitted, ...)  [auto]
  BuildsUpload            → eventBus.emit(.buildUploaded, ...)     [auto]
       ↓
Infrastructure Layer
  LocalPluginRepository   → reads ~/.asc/plugins/*/manifest.json
  ProcessPluginRunner     → spawns subprocess, JSON over stdin/stdout
  LocalPluginEventBus     → discovers subscribed plugins, runs in TaskGroup
       ↓
Domain Layer
  Plugin                  → model + AffordanceProviding
  PluginEvent             → build.uploaded | version.submitted | ...
  PluginEventPayload      → event, appId?, versionId?, buildId?, timestamp, metadata
  PluginResult            → success, message?, error?
  PluginRepository        → @Mockable CRUD protocol
  PluginRunner            → @Mockable run protocol
  PluginEventBus          → @Mockable emit protocol
```

## Domain Models

### `Plugin`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Plugin name (unique identifier) |
| `name` | `String` | Plugin name |
| `version` | `String` | Semver string |
| `description` | `String` | Human-readable description |
| `author` | `String?` | Author (omitted from JSON if nil) |
| `executablePath` | `String` | Absolute path to the `run` executable |
| `subscribedEvents` | `[PluginEvent]` | Events this plugin handles |
| `isEnabled` | `Bool` | Whether the plugin will be invoked |

**Affordances:**
- `listPlugins` — always present
- `uninstall` — always present
- `enable` — present when `isEnabled == false`
- `disable` — present when `isEnabled == true`
- `run.<event>` — one per `PluginEvent.allCases`

### `PluginEvent`

| Raw value | Description |
|-----------|-------------|
| `build.uploaded` | Fired after `asc builds upload` succeeds |
| `version.submitted` | Fired after `asc versions submit` succeeds |
| `version.approved` | Reserved |
| `version.rejected` | Reserved |

### `PluginEventPayload`

| Field | Type | Description |
|-------|------|-------------|
| `event` | `PluginEvent` | The event that fired |
| `appId` | `String?` | App ID (if available) |
| `versionId` | `String?` | Version ID (if available) |
| `buildId` | `String?` | Build/upload ID (if available) |
| `timestamp` | `Date` | ISO 8601 timestamp |
| `metadata` | `[String: String]` | Additional key-value data |

### `PluginResult`

| Field | Type | Description |
|-------|------|-------------|
| `success` | `Bool` | Whether the plugin succeeded |
| `message` | `String?` | Optional success message (omitted from JSON if nil) |
| `error` | `String?` | Optional error description (omitted from JSON if nil) |

## File Map

```
Sources/Domain/Plugins/
├── Plugin.swift                  — Plugin model + Codable + AffordanceProviding
├── PluginEvent.swift             — Event enum (4 cases)
├── PluginEventPayload.swift      — Event payload sent to plugin via stdin
├── PluginResult.swift            — Result read from plugin's stdout
├── PluginRepository.swift        — @Mockable CRUD protocol
├── PluginRunner.swift            — @Mockable execution protocol
└── PluginEventBus.swift          — @Mockable event routing protocol

Sources/Infrastructure/Plugins/
├── LocalPluginRepository.swift   — Reads ~/.asc/plugins/*/manifest.json
├── ProcessPluginRunner.swift     — Subprocess + JSON stdio
└── LocalPluginEventBus.swift     — TaskGroup parallel invocation

Sources/ASCCommand/Commands/Plugins/
├── PluginsCommand.swift          — Parent: asc plugins
├── PluginsList.swift             — asc plugins list
├── PluginsInstall.swift          — asc plugins install <path>
├── PluginsUninstall.swift        — asc plugins uninstall --name
├── PluginsEnable.swift           — asc plugins enable --name
├── PluginsDisable.swift          — asc plugins disable --name
└── PluginsRun.swift              — asc plugins run --name --event

Tests/DomainTests/Plugins/
└── PluginTests.swift             — Domain model + affordance tests

Tests/ASCCommandTests/Commands/Plugins/
├── PluginsListTests.swift        — Command JSON output tests
└── PluginsRunTests.swift         — Command success/failure tests

Wiring files:
  Sources/ASCCommand/ASC.swift           — PluginsCommand registered
  Sources/ASCCommand/ClientProvider.swift — makePluginRepository/Runner/EventBus
  Sources/Infrastructure/Client/ClientFactory.swift — makePlugin* factories
  Sources/ASCCommand/Commands/Versions/VersionsSubmit.swift — emits versionSubmitted
  Sources/ASCCommand/Commands/Builds/BuildsUpload.swift    — emits buildUploaded
```

## Testing

```bash
# Run plugin tests
swift test --filter 'Plugin'

# Run all tests (701 total)
swift test
```

Representative test:

```swift
@Test func `listed plugins include all fields and affordances`() async throws {
    let mockRepo = MockPluginRepository()
    given(mockRepo).listPlugins().willReturn([
        Plugin(
            id: "slack-notify",
            name: "slack-notify",
            version: "1.0.0",
            description: "Send Slack notifications for App Store events",
            author: "Test Author",
            executablePath: "/tmp/slack-notify/run",
            subscribedEvents: [.buildUploaded, .versionSubmitted],
            isEnabled: true
        )
    ])

    let cmd = try PluginsList.parse(["--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == #"""
    {
      "data" : [
        {
          "affordances" : {
            "disable" : "asc plugins disable --name slack-notify",
            ...
          },
          "author" : "Test Author",
          ...
          "isEnabled" : true,
          "name" : "slack-notify",
          ...
        }
      ]
    }
    """#)
}
```

## Extending

### Add a new event type

1. Add a case to `PluginEvent` in `Domain/Plugins/PluginEvent.swift`
2. Wire the event in the relevant command's `execute()` method
3. Update `manifest.json` schema docs

### Add plugin configuration storage

```swift
// In manifest.json, add a "config" field:
struct PluginManifest: Codable {
    // ...
    let config: [String: String]?  // user-facing config schema
}

// Store user config in ~/.asc/plugins/<name>/config.json
// Plugin reads it at startup
```

### Add remote plugin registry

```bash
asc plugins search <query>           # search a registry
asc plugins install --remote <name>  # install from registry
```
