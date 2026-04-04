# App Shots

AI-powered App Store screenshot design, generation, and localization. The `asc app-shots` command provides a template-based workflow for composing marketing screenshots and uses Gemini AI to generate polished final images.

Three workflows:

**Workflow A — Templates + AI generation:**
1. **`asc app-shots templates list`** — browse available templates with previewable affordances
2. **`asc app-shots templates apply`** — apply a template to your screenshot → previewable composed design
3. **`asc app-shots generate`** — Gemini AI generates the final polished marketing screenshots

**Workflow B — AI-only generation:**
1. **`asc-app-shots` skill** — Claude fetches App Store metadata, analyzes screenshots, writes a `ScreenshotDesign` JSON
2. **`asc app-shots generate`** — reads the design + screenshots, calls Gemini, writes `screen-{index}.png`
3. **`asc app-shots translate`** *(optional)* — recreates screenshots with translated text for each locale

**Workflow C — HTML (no AI needed):**
1. **`asc app-shots html`** — generates a self-contained HTML page from a design; open in browser to preview and export PNGs

---

## CLI Usage

### `asc app-shots templates list`

List available screenshot templates. Templates are registered by plugins (e.g. Blitz Screenshots provides 23 built-in templates).

| Flag | Default | Description |
|------|---------|-------------|
| `--size` | — | Filter by size: `portrait`, `landscape`, `portrait43`, `square` |
| `--preview` | — | Include self-contained HTML preview for each template |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON output |

```bash
# List all templates
asc app-shots templates list

# Filter by screen orientation
asc app-shots templates list --size portrait

# Include visual previews (HTML in affordances)
asc app-shots templates list --preview

# Table format
asc app-shots templates list --output table
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "top-hero",
      "name": "Top Hero",
      "category": "bold",
      "supportedSizes": ["portrait"],
      "deviceCount": 1,
      "affordances": {
        "preview": "asc app-shots templates get --id top-hero --preview",
        "apply": "asc app-shots templates apply --id top-hero --screenshot screen.png",
        "detail": "asc app-shots templates get --id top-hero",
        "listAll": "asc app-shots templates list"
      }
    }
  ]
}
```

### `asc app-shots templates get`

Get details of a specific template, optionally with a visual preview.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--preview` | — | Output self-contained HTML preview page |

```bash
# Get template details as JSON
asc app-shots templates get --id top-hero

# Get visual preview — save and open in browser
asc app-shots templates get --id top-hero --preview > preview.html
open preview.html
```

### `asc app-shots templates apply`

Apply a template to a screenshot. Returns a `ScreenDesign` with affordances for next steps, or a visual preview with `--preview`.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Subtitle text |
| `--app-name` | `My App` | App name |
| `--preview` | — | Output self-contained HTML preview with real screenshot |

```bash
# Apply template → get design JSON with affordances
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen1.png \
  --headline "Ship Faster"

# Preview the result — save and open in browser
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen1.png \
  --headline "Ship Faster" \
  --preview > composed.html
open composed.html
```

**JSON output:**
```json
{
  "data": [
    {
      "heading": "Ship Faster",
      "screenshotFile": ".asc/app-shots/screen1.png",
      "isComplete": true,
      "affordances": {
        "generate": "asc app-shots generate --design design.json",
        "preview": "asc app-shots templates apply --id top-hero --screenshot .asc/app-shots/screen1.png --headline \"Ship Faster\"",
        "changeTemplate": "asc app-shots templates list",
        "templateDetail": "asc app-shots templates get --id top-hero"
      }
    }
  ]
}
```

---

### `asc app-shots generate`

Generate marketing PNG images using Gemini AI. Reads a `ScreenshotDesign` JSON file, discovers or accepts screenshot files, and outputs one PNG per screen.

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Path to the ScreenshotDesign JSON file |
| `--gemini-api-key` | — | Gemini API key (falls back to `GEMINI_API_KEY` env var, then stored config) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini image generation model |
| `--output-dir` | `.asc/app-shots/output` | Directory to write generated PNG files |
| `--output-width` | `1320` | Output PNG width in pixels |
| `--output-height` | `2868` | Output PNG height in pixels |
| `--device-type` | — | Named device type (e.g. `APP_IPHONE_69`) — overrides width/height |
| `--style-reference` | — | Path to a reference image whose visual style Gemini should replicate |
| `<screenshots>` | *(auto-discovered)* | Screenshot files; omit to auto-discover from plan directory |

```bash
# Zero-argument happy path
asc app-shots generate

# With style reference
asc app-shots generate --style-reference ~/Downloads/competitor-shot.png

# Named device type
asc app-shots generate --device-type APP_IPHONE_69

# Explicit plan + screenshots
asc app-shots generate \
  --plan .asc/app-shots/app-shots-plan.json \
  .asc/app-shots/screen1.png .asc/app-shots/screen2.png
```

---

### `asc app-shots translate`

Translate already-generated screenshots into one or more locales.

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Source design JSON |
| `--from` | `en` | Source locale label |
| `--to` | *(required, repeatable)* | Target locale(s) |
| `--source-dir` | `.asc/app-shots/output` | Directory containing existing screenshots |
| `--style-reference` | — | Path to a reference image for style consistency |

```bash
asc app-shots translate --to zh --to ja
```

---

### `asc app-shots html`

Generate a self-contained HTML page from a ScreenshotDesign — no AI API key needed.

```bash
asc app-shots html
asc app-shots html --device-type APP_IPHONE_67
```

---

### `asc app-shots config`

Manage the Gemini API key.

```bash
asc app-shots config --gemini-api-key AIzaSy...   # Save key
asc app-shots config                                # Show current key
asc app-shots config --remove                       # Remove stored key
```

---

## Typical Workflow

### Template-based (recommended)

```bash
# 1. Save Gemini API key once
asc app-shots config --gemini-api-key AIzaSy...

# 2. Browse templates
asc app-shots templates list --output table

# 3. Preview a template
asc app-shots templates get --id top-hero --preview > preview.html
open preview.html

# 4. Apply template to your screenshot
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen1.png \
  --headline "Ship Faster" \
  --preview > composed.html
open composed.html

# 5. Generate final marketing images
asc app-shots generate

# 6. Translate
asc app-shots translate --to zh --to ja
```

### AI-only (skill-driven)

```bash
# 1. Save Gemini API key
asc app-shots config --gemini-api-key AIzaSy...

# 2. Use the asc-app-shots skill in Claude Code:
#    "Plan my App Store screenshots for app 6736834466"
#    → Claude writes .asc/app-shots/app-shots-plan.json

# 3. Generate
asc app-shots generate

# 4. Translate
asc app-shots translate --to zh --to ja
```

---

## Architecture

```
ASCCommand                          Domain                              Infrastructure
+-------------------------------+   +----------------------------------+  +--------------------------------+
| AppShotsCommand               |   | ScreenshotDesign                 |  | GeminiScreenshotGeneration     |
|   templates list/get/apply    |-->| ScreenDesign (rich domain)       |  |   Repository                   |
|   generate                    |   |   template: ScreenshotTemplate?  |  |   POST generateContent         |
|   translate                   |   |   heading, screenshotFile        |  |   (native Gemini API)          |
|   html                        |   |   previewHTML, isComplete        |  +--------------------------------+
|   config                      |   |   affordances                    |  | AggregateTemplateRepository    |
+-------------------------------+   | ScreenshotTemplate               |  |   (actor, provider pattern)    |
                                    |   id, name, category             |  |   Aggregates from plugins      |
                                    |   textSlots, deviceSlots         |  +--------------------------------+
                                    |   previewHTML, affordances       |  | FileAppShotsConfigStorage      |
                                    | TemplateProvider (protocol)      |  |   ~/.asc/app-shots-config.json |
                                    |   Plugins register templates     |  +--------------------------------+
                                    | TemplateRepository (protocol)    |
                                    | TemplateHTMLRenderer             |
                                    |   render(template, content?)     |
                                    +----------------------------------+
```

**Dependency flow:** `ASCCommand → Domain ← Infrastructure`

- **Domain**: Rich domain models (`ScreenshotDesign`, `ScreenDesign`, `ScreenshotTemplate`) with behavior (`previewHTML`, `isComplete`, `affordances`). `TemplateProvider` protocol allows plugins to register templates. `TemplateHTMLRenderer` produces self-contained HTML previews.
- **Infrastructure**: `AggregateTemplateRepository` is an actor that aggregates templates from all registered `TemplateProvider`s. `GeminiScreenshotGenerationRepository` calls the native Gemini API. Blitz plugin registers via `BlitzTemplateProvider`.
- **ASCCommand**: `templates list/get/apply` for browsing and composing. `generate` for AI generation. `translate` for localization.

---

## Domain Models

### `ScreenshotDesign` (renamed from ScreenPlan)

Main design model — a collection of screens. Implements `AffordanceProviding`.

| Field | Type | Description |
|-------|------|-------------|
| `appId` | `String` | App ID (also serves as the model's `id`) |
| `appName` | `String` | App display name |
| `tagline` | `String` | Marketing tagline |
| `appDescription` | `String?` | Summary for Gemini context |
| `tone` | `ScreenTone` | Visual tone (`bold`, `minimal`, `elegant`, `professional`, `playful`) |
| `colors` | `ScreenColors` | Color palette (`primary`, `accent`, `text`, `subtext`) |
| `screens` | `[ScreenDesign]` | Ordered list of screen designs |

### `ScreenDesign` (rich domain object)

A single screen — knows its template, content, and how to preview itself.

| Field | Type | Description |
|-------|------|-------------|
| `index` | `Int` | Screen order (0-based) |
| `template` | `ScreenshotTemplate?` | Applied template (runtime, excluded from Codable) |
| `screenshotFile` | `String` | Source screenshot path |
| `heading` | `String` | Main headline |
| `subheading` | `String` | Supporting text |

**Computed properties:**
| Property | Type | Description |
|----------|------|-------------|
| `isComplete` | `Bool` | Has template + heading + screenshot |
| `previewHTML` | `String` | Self-contained HTML preview page |

**Affordances:**
| Key | Command |
|-----|---------|
| `generate` | `asc app-shots generate --design design.json` |
| `preview` | `asc app-shots templates apply --id {id} --screenshot {file} --headline "{heading}"` |
| `changeTemplate` | `asc app-shots templates list` |
| `templateDetail` | `asc app-shots templates get --id {id}` |

### `ScreenshotTemplate`

Reusable template for composing screenshots. Registered by plugins via `TemplateProvider`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String` | Display name |
| `category` | `TemplateCategory` | `bold`, `minimal`, `elegant`, `professional`, `playful`, `showcase`, `custom` |
| `supportedSizes` | `[ScreenSize]` | `portrait`, `landscape`, `portrait43`, `square` |
| `description` | `String` | Human-readable description |
| `background` | `SlideBackground` | `.solid(color)` or `.gradient(from, to, angle)` |
| `textSlots` | `[TemplateTextSlot]` | Text positions with role, preview text, style |
| `deviceSlots` | `[TemplateDeviceSlot]` | Device positions with scale, rotation |

**Computed properties:**
| Property | Type | Description |
|----------|------|-------------|
| `isPortrait` | `Bool` | Supports portrait orientation |
| `isLandscape` | `Bool` | Supports landscape orientation |
| `deviceCount` | `Int` | Number of device slots |
| `previewHTML` | `String` | Self-contained HTML preview page |

**Affordances:**
| Key | Command |
|-----|---------|
| `preview` | `asc app-shots templates get --id {id} --preview` |
| `apply` | `asc app-shots templates apply --id {id} --screenshot screen.png` |
| `detail` | `asc app-shots templates get --id {id}` |
| `listAll` | `asc app-shots templates list` |

### `TemplateProvider` (protocol)

```swift
@Mockable
public protocol TemplateProvider: Sendable {
    var providerId: String { get }
    func templates() async throws -> [ScreenshotTemplate]
}
```

Plugins implement this to register templates. Blitz plugin provides 23 built-in templates via `BlitzTemplateProvider`.

### `TemplateRepository` (protocol)

```swift
@Mockable
public protocol TemplateRepository: Sendable {
    func listTemplates(size: ScreenSize?) async throws -> [ScreenshotTemplate]
    func getTemplate(id: String) async throws -> ScreenshotTemplate?
}
```

### `TemplateHTMLRenderer`

Renders self-contained HTML previews. Uses `cqi` units + `container-type:inline-size` for responsive scaling.

```swift
// Preview mode — wireframe phone + sample text
TemplateHTMLRenderer.renderPage(template)

// Applied mode — real screenshot + real headline
TemplateHTMLRenderer.renderPage(template, content: TemplateContent(
    headline: "Ship Faster",
    screenshotFile: "screen.png"
))
```

---

## File Map

### Sources

```
Sources/
├── Domain/ScreenshotPlans/
│   ├── ScreenshotDesign.swift         (renamed from ScreenPlan)
│   ├── ScreenDesign.swift             (rich domain, carries template)
│   ├── ScreenshotTemplate.swift       (template model + affordances)
│   ├── TemplateRepository.swift       (TemplateProvider + TemplateRepository protocols)
│   ├── TemplateContent.swift          (content to fill into template)
│   ├── TemplateHTMLRenderer.swift     (HTML preview renderer)
│   ├── ScreenTone.swift
│   ├── LayoutMode.swift
│   ├── ScreenColors.swift
│   ├── ScreenshotGenerationRepository.swift
│   ├── AppShotsConfig.swift
│   ├── AppShotsConfigStorage.swift
│   └── CompositionPlan.swift          (deterministic layout plan)
├── Infrastructure/ScreenshotPlans/
│   ├── GeminiScreenshotGenerationRepository.swift
│   ├── AggregateTemplateRepository.swift  (actor, aggregates providers)
│   └── FileAppShotsConfigStorage.swift
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift
    ├── AppShotsTemplates.swift        (list, get, apply)
    ├── AppShotsGenerate.swift
    ├── AppShotsTranslate.swift
    ├── AppShotsHTML.swift
    └── AppShotsConfig.swift
```

### Tests

```
Tests/
├── DomainTests/ScreenshotPlans/
│   ├── ScreenshotDesignTests.swift
│   ├── ScreenshotTemplateTests.swift
│   ├── ScreenDesignTests.swift
│   └── AppShotsConfigTests.swift
├── InfrastructureTests/ScreenshotPlans/
│   ├── AggregateTemplateRepositoryTests.swift
│   ├── GeminiScreenshotGenerationRepositoryTests.swift
│   └── FileAppShotsConfigStorageTests.swift
└── ASCCommandTests/Commands/AppShots/
    ├── AppShotsTemplatesTests.swift
    ├── AppShotsGenerateTests.swift
    ├── AppShotsTranslateTests.swift
    └── AppShotsConfigTests.swift
```

### Blitz Plugin (template provider)

```
examples/blitz-screenshots/
├── Sources/BlitzPlugin/
│   ├── Templates/
│   │   └── BlitzTemplateProvider.swift   (registers 23 templates)
│   ├── Resources/
│   │   └── templates.json                (template data, single source of truth)
│   └── BlitzPlugin.swift                 (plugin entry, calls register())
└── plugin/
    ├── ui/                               (web UI)
    └── bridge/                           (Claude AI compose bridge)
```

---

## Device Sizes

| Display Type | Device | Width | Height | Required |
|---|---|---|---|---|
| `APP_IPHONE_69` | iPhone 6.9" | 1320 | 2868 | ✅ |
| `APP_IPHONE_67` | iPhone 6.7" | 1290 | 2796 | ✅ |
| `APP_IPHONE_65` | iPhone 6.5" | 1260 | 2736 | ✅ |
| `APP_IPAD_PRO_129` | iPad 13" | 2048 | 2732 | ✅ |

---

## Testing

```bash
swift test --filter 'ScreenshotTemplateTests'           # Template domain (8)
swift test --filter 'ScreenDesignRich'                   # ScreenDesign rich domain (7)
swift test --filter 'AggregateTemplateRepositoryTests'   # Template aggregation (5)
swift test --filter 'AppShotsTemplatesTests'             # Template commands (6)
swift test --filter 'ScreenshotDesignTests'              # Design model (9)
swift test --filter 'AppShots'                           # All app-shots tests
```
