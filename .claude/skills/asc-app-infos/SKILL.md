---
name: asc-app-infos
description: |
  Manage App Store app info and per-locale metadata using the `asc` CLI tool.
  Use this skill when:
  (1) Listing app info records: "asc app-infos list --app-id ID"
  (2) Listing per-locale app metadata: "asc app-info-localizations list --app-info-id ID"
  (3) Creating a new locale entry: "asc app-info-localizations create --app-info-id ID --locale en-US --name 'My App'"
  (4) Updating name, subtitle, or privacy URLs: "asc app-info-localizations update --localization-id ID --name 'New Name'"
  (5) Navigating to age rating: "asc age-rating get --app-info-id ID" (use getAgeRating affordance)
  (6) User says "update app name", "update subtitle", "set privacy policy URL", "list app info", "manage app metadata"
---

# asc App Info & Localizations

Manage app-level metadata (name, subtitle, privacy policy URLs) via the `asc` CLI.

> **Note**: This is distinct from version-level metadata (`asc version-localizations`) which handles
> "What's New", description, and keywords. App info localizations hold the persistent app name and subtitle.

## List App Infos

Each app has one AppInfo record (rarely more). Get the AppInfo ID needed for subsequent commands.

```bash
asc app-infos list --app-id <APP_ID> [--pretty]
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "info-abc123",
      "appId": "6746148194",
      "affordances": {
        "listLocalizations": "asc app-info-localizations list --app-info-id info-abc123",
        "listAppInfos":      "asc app-infos list --app-id 6746148194",
        "getAgeRating":      "asc age-rating get --app-info-id info-abc123"
      }
    }
  ]
}
```

## List Localizations

```bash
asc app-info-localizations list --app-info-id <APP_INFO_ID> [--output table]
```

**Table output:**
```
ID        Locale    Name            Subtitle
--------  --------  --------------  --------------------
loc-001   en-US     My App          Do things faster
loc-002   zh-Hans   我的应用         更快地完成任务
```

## Create Localization

Create a new locale entry. `--name` is required (up to 30 characters).

```bash
asc app-info-localizations create \
  --app-info-id <APP_INFO_ID> \
  --locale zh-Hans \
  --name "我的应用"
```

Common locales: `en-US`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `de`, `fr`

## Update Localization

All fields are optional — only provided fields are changed (PATCH semantics).

```bash
asc app-info-localizations update \
  --localization-id <LOCALIZATION_ID> \
  [--name "New App Name"] \
  [--subtitle "Do things faster"] \
  [--privacy-policy-url "https://example.com/privacy"] \
  [--privacy-choices-url "https://example.com/choices"] \
  [--privacy-policy-text "Our privacy policy text"]
```

| Flag | Description |
|------|-------------|
| `--name` | App name (up to 30 characters) |
| `--subtitle` | Subtitle (up to 30 characters) |
| `--privacy-policy-url` | Main privacy policy URL |
| `--privacy-choices-url` | Privacy choices/opt-out URL |
| `--privacy-policy-text` | Inline privacy policy text |

## CAEOAS Affordances

Every response includes ready-to-run follow-up commands:

**AppInfo:**
```json
{
  "affordances": {
    "listLocalizations": "asc app-info-localizations list --app-info-id <ID>",
    "listAppInfos":      "asc app-infos list --app-id <APP_ID>",
    "getAgeRating":      "asc age-rating get --app-info-id <ID>"
  }
}
```

**AppInfoLocalization:**
```json
{
  "affordances": {
    "listLocalizations":  "asc app-info-localizations list --app-info-id <APP_INFO_ID>",
    "updateLocalization": "asc app-info-localizations update --localization-id <ID>"
  }
}
```

## Typical Workflow

```bash
APP_ID="6746148194"

# 1. Get the AppInfo ID
APP_INFO_ID=$(asc app-infos list --app-id "$APP_ID" | jq -r '.data[0].id')

# 2. See existing localizations
asc app-info-localizations list --app-info-id "$APP_INFO_ID" --output table

# 3a. Update an existing locale
LOC_ID=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .id')
asc app-info-localizations update \
  --localization-id "$LOC_ID" \
  --name "My App" \
  --subtitle "Do things faster" \
  --privacy-policy-url "https://example.com/privacy"

# 3b. Add a new locale
asc app-info-localizations create \
  --app-info-id "$APP_INFO_ID" \
  --locale zh-Hans \
  --name "我的应用"

# 4. Check age rating (navigate via affordance)
asc age-rating get --app-info-id "$APP_INFO_ID"
```

## Two Localization Types

| Type | Commands | Fields |
|------|----------|--------|
| `AppInfoLocalization` | `asc app-info-localizations *` | name, subtitle, privacyPolicyUrl, privacyChoicesUrl, privacyPolicyText |
| `AppStoreVersionLocalization` | `asc version-localizations *` | whatsNew, description, keywords, screenshots |

App info localizations are persistent across app versions. Version localizations are per-release.