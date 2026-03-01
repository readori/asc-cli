# App Infos Feature

Manage app-level metadata (name, subtitle, privacy policy, categories) for an app via the App Store Connect API. These fields appear on the App Store listing and persist across versions — distinct from version-specific release notes managed through `AppStoreVersionLocalization`.

## CLI Usage

### List App Infos

List the AppInfo records for an app. Each app has one AppInfo per active state (typically one).

```bash
asc app-infos list --app-id <APP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc app-infos list --app-id 6746148194 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "info-abc123",
      "appId": "6746148194",
      "affordances": {
        "getAgeRating":      "asc age-rating get --app-info-id info-abc123",
        "listAppInfos":      "asc app-infos list --app-id 6746148194",
        "listLocalizations": "asc app-info-localizations list --app-info-id info-abc123",
        "updateCategories":  "asc app-infos update --app-info-id info-abc123"
      }
    }
  ]
}
```

---

### Update App Info (Categories)

Set primary and secondary category for an app. All category flags are optional — only provided flags are sent.

```bash
asc app-infos update --app-info-id <APP_INFO_ID> \
  [--primary-category <ID>] \
  [--primary-subcategory-one <ID>] \
  [--primary-subcategory-two <ID>] \
  [--secondary-category <ID>] \
  [--secondary-subcategory-one <ID>] \
  [--secondary-subcategory-two <ID>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-info-id` | *(required)* | App info ID |
| `--primary-category` | *(optional)* | Primary category ID (e.g. `6014`) |
| `--primary-subcategory-one` | *(optional)* | First subcategory of primary category |
| `--primary-subcategory-two` | *(optional)* | Second subcategory of primary category |
| `--secondary-category` | *(optional)* | Secondary category ID |
| `--secondary-subcategory-one` | *(optional)* | First subcategory of secondary category |
| `--secondary-subcategory-two` | *(optional)* | Second subcategory of secondary category |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
# Set Games as primary, Action as subcategory
asc app-infos update \
  --app-info-id info-abc123 \
  --primary-category 6014 \
  --primary-subcategory-one 7001
```

---

### List App Categories

Browse available App Store categories and subcategories. Use returned IDs with `asc app-infos update`.

```bash
asc app-categories list [--platform <PLATFORM>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--platform` | *(optional)* | Filter by platform: `IOS`, `MAC_OS`, `TV_OS` |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
# All categories
asc app-categories list --output table

# iOS only
asc app-categories list --platform IOS --output table
```

**Table output:**

```
ID      Platforms     ParentId
------  ------------  --------
6014    IOS, MAC_OS   -
7001    IOS, MAC_OS   6014
7002    IOS, MAC_OS   6014
6005    IOS, MAC_OS   -
```

---

### List App Info Localizations

List all per-locale metadata entries for a given AppInfo.

```bash
asc app-info-localizations list --app-info-id <APP_INFO_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-info-id` | *(required)* | App info ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Table output:**

```
ID          Locale    Name            Subtitle
----------  --------  --------------  --------------------
loc-001     en-US     My App          Do things faster
loc-002     zh-Hans   我的应用          更快地完成任务
loc-003     ja        マイアプリ         -
```

---

### Create App Info Localization

Create a new localization for a locale that doesn't exist yet.

```bash
asc app-info-localizations create --app-info-id <APP_INFO_ID> --locale <LOCALE> --name <NAME>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-info-id` | *(required)* | App info ID |
| `--locale` | *(required)* | Locale identifier (e.g. `en-US`, `zh-Hans`) |
| `--name` | *(required)* | App name (up to 30 characters) |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc app-info-localizations create \
  --app-info-id info-abc123 \
  --locale zh-Hans \
  --name "我的应用"
```

---

### Update App Info Localization

Update name, subtitle, or privacy policy fields for an existing localization. All fields are optional — only provided fields are changed (PATCH semantics).

```bash
asc app-info-localizations update --localization-id <LOCALIZATION_ID> \
  [--name <n>] \
  [--subtitle <s>] \
  [--privacy-policy-url <url>] \
  [--privacy-choices-url <url>] \
  [--privacy-policy-text <text>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | Localization ID |
| `--name` | *(optional)* | App name (up to 30 characters) |
| `--subtitle` | *(optional)* | Subtitle (up to 30 characters) |
| `--privacy-policy-url` | *(optional)* | Main privacy policy URL |
| `--privacy-choices-url` | *(optional)* | Privacy choices/opt-out URL |
| `--privacy-policy-text` | *(optional)* | Inline privacy policy text |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

---

### Delete App Info Localization

Remove a localization entry by ID.

```bash
asc app-info-localizations delete --localization-id <LOCALIZATION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | Localization ID to delete |

**Example:**

```bash
asc app-info-localizations delete --localization-id loc-001
```

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. Get the AppInfo ID (each app has one)
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')

# 3. See what localizations already exist
asc app-info-localizations list --app-info-id "$APP_INFO_ID" --output table

# 4a. Update an existing locale
LOC_ID=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .id')
asc app-info-localizations update \
  --localization-id "$LOC_ID" \
  --name "My App" \
  --subtitle "Do things faster"

# 4b. Add a new locale
asc app-info-localizations create \
  --app-info-id "$APP_INFO_ID" \
  --locale zh-Hans \
  --name "我的应用"

# 4c. Remove an unwanted locale
asc app-info-localizations delete --localization-id <LOCALIZATION_ID>

# 5. Set app category (look up IDs first)
asc app-categories list --platform IOS --output table
asc app-infos update \
  --app-info-id "$APP_INFO_ID" \
  --primary-category 6014 \
  --secondary-category 6005

# 6. Navigate to age rating from AppInfo affordance
asc age-rating get --app-info-id "$APP_INFO_ID"
```

Each response includes an `affordances` field with ready-to-run follow-up commands for AI agents.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                     App Infos Feature                                 │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ASC API                     Infrastructure            Domain         │
│  ┌────────────────────────┐  ┌──────────────────────┐  ┌───────────┐  │
│  │ GET /v1/apps/{id}/     │  │                      │  │ AppInfo   │  │
│  │ appInfos               │─▶│ SDKAppInfo           │─▶│ (struct)  │  │
│  │                        │  │ Repository           │  └───────────┘  │
│  │ PATCH /v1/appInfos/    │  │                      │  ┌───────────┐  │
│  │ {id}                   │─▶│ (AppInfoRepository)  │─▶│AppInfoLoc-│  │
│  │                        │  │                      │  │alization  │  │
│  │ GET /v1/appInfos/{id}/ │  │                      │  └───────────┘  │
│  │ appInfoLocalizations   │─▶│                      │  ┌───────────┐  │
│  │                        │  │                      │  │AppCategory│  │
│  │ POST /v1/appInfo-      │  │ SDKAppCategory       │─▶│ (struct)  │  │
│  │ Localizations          │─▶│ Repository           │  └───────────┘  │
│  │                        │  │                      │                  │
│  │ PATCH /v1/appInfo-     │  │ (AppCategory         │                  │
│  │ Localizations/{id}     │─▶│  Repository)         │                  │
│  │                        │  │                      │                  │
│  │ DELETE /v1/appInfo-    │  │                      │                  │
│  │ Localizations/{id}     │─▶│                      │                  │
│  │                        │  │                      │                  │
│  │ GET /v1/appCategories  │─▶│                      │                  │
│  └────────────────────────┘  └──────────────────────┘  └───────────┘  │
│                                                                       │
│  Resource hierarchy:                                                  │
│  App → AppInfo → AppInfoLocalization (name, subtitle, privacy URLs)  │
│  (distinct from App → AppStoreVersion → AppStoreVersionLocalization) │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  ASCCommand Layer                                               │  │
│  │  asc app-infos list --app-id <id>                              │  │
│  │  asc app-infos update --app-info-id <id>                       │  │
│  │  asc app-categories list [--platform IOS]                      │  │
│  │  asc app-info-localizations list --app-info-id <id>            │  │
│  │  asc app-info-localizations create --app-info-id <id>          │  │
│  │  asc app-info-localizations update --localization-id <id>      │  │
│  │  asc app-info-localizations delete --localization-id <id>      │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `AppInfo`

A thin container that groups all localizations and category assignments for an app's metadata.

```swift
public struct AppInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String               // Parent ID, always injected by Infrastructure
    public let primaryCategoryId: String?  // Nil fields omitted from JSON (synthesized Codable)
    public let primarySubcategoryOneId: String?
    public let primarySubcategoryTwoId: String?
    public let secondaryCategoryId: String?
    public let secondarySubcategoryOneId: String?
    public let secondarySubcategoryTwoId: String?
}

extension AppInfo: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getAgeRating":      "asc age-rating get --app-info-id \(id)",
            "listAppInfos":      "asc app-infos list --app-id \(appId)",
            "listLocalizations": "asc app-info-localizations list --app-info-id \(id)",
            "updateCategories":  "asc app-infos update --app-info-id \(id)",
        ]
    }
}
```

### `AppInfoLocalization`

Per-locale app metadata: name, subtitle, and privacy URLs/text. Nil fields are omitted from JSON output.

```swift
public struct AppInfoLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appInfoId: String         // Parent ID, always injected by Infrastructure
    public let locale: String            // "en-US", "zh-Hans", etc.
    public let name: String?
    public let subtitle: String?
    public let privacyPolicyUrl: String?
    public let privacyChoicesUrl: String?
    public let privacyPolicyText: String?
}

extension AppInfoLocalization: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete":             "asc app-info-localizations delete --localization-id \(id)",
            "listLocalizations":  "asc app-info-localizations list --app-info-id \(appInfoId)",
            "updateLocalization": "asc app-info-localizations update --localization-id \(id)",
        ]
    }
}
```

### `AppCategory`

An App Store category or subcategory. Subcategories carry a non-nil `parentId`.

```swift
public struct AppCategory: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let platforms: [String]   // e.g. ["IOS", "MAC_OS"]
    public let parentId: String?     // Non-nil for subcategories
}

extension AppCategory: AffordanceProviding {
    public var affordances: [String: String] {
        ["listCategories": "asc app-categories list"]
    }
}
```

### `AppInfoRepository`

The DI boundary between the command layer and the API. Annotated with `@Mockable` for testing.

```swift
@Mockable
public protocol AppInfoRepository: Sendable {
    func listAppInfos(appId: String) async throws -> [AppInfo]
    func listLocalizations(appInfoId: String) async throws -> [AppInfoLocalization]
    func createLocalization(appInfoId: String, locale: String, name: String) async throws -> AppInfoLocalization
    func updateLocalization(
        id: String,
        name: String?,
        subtitle: String?,
        privacyPolicyUrl: String?,
        privacyChoicesUrl: String?,
        privacyPolicyText: String?
    ) async throws -> AppInfoLocalization
    func deleteLocalization(id: String) async throws
    func updateCategories(
        id: String,
        primaryCategoryId: String?,
        primarySubcategoryOneId: String?,
        primarySubcategoryTwoId: String?,
        secondaryCategoryId: String?,
        secondarySubcategoryOneId: String?,
        secondarySubcategoryTwoId: String?
    ) async throws -> AppInfo
}
```

### `AppCategoryRepository`

```swift
@Mockable
public protocol AppCategoryRepository: Sendable {
    func listCategories(platform: String?) async throws -> [AppCategory]
}
```

### Updated `App` affordances

`App` also exposes `listAppInfos`:

```swift
extension App: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listVersions":  "asc versions list --app-id \(id)",
            "listAppInfos":  "asc app-infos list --app-id \(id)",
        ]
    }
}
```

---

## File Map

```
Sources/
├── Domain/Apps/AppInfos/
│   ├── AppInfo.swift                      # Value type + AffordanceProviding (6 category fields)
│   ├── AppInfoLocalization.swift          # Value type + AffordanceProviding (custom Codable)
│   ├── AppInfoRepository.swift            # @Mockable protocol (6 methods)
│   ├── AppCategory.swift                  # Value type + AffordanceProviding + AppCategoryRepository
│   ├── AgeRatingDeclaration.swift         # Age rating types (separate feature)
│   └── AgeRatingDeclarationRepository.swift
│
├── Infrastructure/Apps/AppInfos/
│   ├── SDKAppInfoRepository.swift         # Implements AppInfoRepository; maps SDK → domain
│   ├── SDKAppCategoryRepository.swift     # Implements AppCategoryRepository; merges data+included
│   └── SDKAgeRatingDeclarationRepository.swift
│
└── ASCCommand/Commands/
    ├── AppInfos/
    │   └── AppInfosCommand.swift          # AppInfosCommand + AppInfosList + AppInfosUpdate
    ├── AppCategories/
    │   └── AppCategoriesCommand.swift     # AppCategoriesCommand + AppCategoriesList
    ├── AppInfoLocalizations/
    │   └── AppInfoLocalizationsCommand.swift  # List + Create + Update + Delete subcommands
    └── AgeRating/
        └── AgeRatingCommand.swift         # AgeRatingGet + AgeRatingUpdate

Tests/
├── DomainTests/Apps/AppInfos/
│   ├── AppInfoTests.swift                 # Parent ID, category fields, affordances
│   ├── AppInfoLocalizationTests.swift     # Optional fields, delete affordance
│   └── AppCategoryTests.swift             # parentId, platforms, affordances
├── InfrastructureTests/Apps/AppInfos/
│   ├── SDKAppInfoRepositoryTests.swift    # Parent ID injection, field mapping, categories
│   └── SDKAppCategoryRepositoryTests.swift  # Flat list from data+included, platforms, parentId
├── ASCCommandTests/Commands/AppInfos/
│   ├── AppInfosListTests.swift            # JSON with updateCategories affordance
│   └── AppInfosUpdateTests.swift          # Category flags forwarding + affordances
├── ASCCommandTests/Commands/AppCategories/
│   └── AppCategoriesListTests.swift       # Top-level + subcategory JSON
└── ASCCommandTests/Commands/AppInfoLocalizations/
    ├── AppInfoLocalizationsListTests.swift    # JSON with delete affordance
    ├── AppInfoLocalizationsCreateTests.swift  # JSON with delete affordance
    ├── AppInfoLocalizationsUpdateTests.swift  # Privacy fields capture
    └── AppInfoLocalizationsDeleteTests.swift  # Verifies repo.deleteLocalization called
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeAppInfoRepository(authProvider:)`, `makeAppCategoryRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeAppInfoRepository()`, `makeAppCategoryRepository()` |
| `Sources/ASCCommand/ASC.swift` | Added `AppInfosCommand.self`, `AppInfoLocalizationsCommand.self`, `AppCategoriesCommand.self` |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added `makeAppInfo()`, `makeAppInfoLocalization()`, `makeAppCategory()` |

---

## App Store Connect API Reference

| Endpoint | SDK call | Used by |
|----------|----------|---------|
| `GET /v1/apps/{id}/appInfos` | `.apps.id(id).appInfos.get()` | `listAppInfos` |
| `PATCH /v1/appInfos/{id}` | `.appInfos.id(id).patch(body)` | `updateCategories` |
| `GET /v1/appInfos/{id}/appInfoLocalizations` | `.appInfos.id(id).appInfoLocalizations.get()` | `listLocalizations` |
| `POST /v1/appInfoLocalizations` | `.appInfoLocalizations.post(body)` | `createLocalization` |
| `PATCH /v1/appInfoLocalizations/{id}` | `.appInfoLocalizations.id(id).patch(body)` | `updateLocalization` |
| `DELETE /v1/appInfoLocalizations/{id}` | `.appInfoLocalizations.id(id).delete` | `deleteLocalization` |
| `GET /v1/appCategories` | `.appCategories.get(...)` with `include: [.subcategories]` | `listCategories` |

The `GET /v1/appCategories` call returns top-level categories in `data[]` and their subcategories in `included[]`. `SDKAppCategoryRepository` combines both into a flat list. `updateCategories` extracts `appId` from the PATCH response's `relationships.app.data.id`.

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

```swift
// Infrastructure: parent ID injection
@Test func `listAppInfos maps primary category id from relationships`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(AppInfosResponse(
        data: [
            AppInfo(
                type: .appInfos,
                id: "info-1",
                relationships: .init(primaryCategory: .init(data: .init(type: .appCategories, id: "6014")))
            ),
        ],
        links: .init(this: "")
    ))
    let repo = SDKAppInfoRepository(client: stub)
    let result = try await repo.listAppInfos(appId: "app-1")
    #expect(result[0].primaryCategoryId == "6014")
}

// Command: exact JSON assertion
@Test func `updated app info with primary category is returned with affordances`() async throws {
    let mockRepo = MockAppInfoRepository()
    given(mockRepo)
        .updateCategories(id: .any, primaryCategoryId: .any, ...)
        .willReturn(AppInfo(id: "info-1", appId: "app-1", primaryCategoryId: "6014"))

    let cmd = try AppInfosUpdate.parse(["--app-info-id", "info-1", "--primary-category", "6014", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "getAgeRating" : "asc age-rating get --app-info-id info-1",
            "listAppInfos" : "asc app-infos list --app-id app-1",
            "listLocalizations" : "asc app-info-localizations list --app-info-id info-1",
            "updateCategories" : "asc app-infos update --app-info-id info-1"
          },
          "appId" : "app-1",
          "id" : "info-1",
          "primaryCategoryId" : "6014"
        }
      ]
    }
    """)
}
```

Run the full test suite:

```bash
swift test
```

---

## Extending the Feature

### Adding localization filtering

Filter by locale when listing:

```swift
// Domain
func listLocalizations(appInfoId: String, locale: String?) async throws -> [AppInfoLocalization]

// Command
@Option var locale: String?
```

### Adding primary category lookup by name

Map human-readable names to IDs:

```swift
// asc app-categories list --platform IOS | jq '.data[] | select(.id == "6014")'
// Returns the category with platforms and parentId for subcategory lookup
```
