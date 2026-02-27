# In-App Purchases & Subscriptions

Manage in-app purchases and auto-renewable subscriptions via App Store Connect.

## CLI Usage

### `asc iap list`

List in-app purchases for an app.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | ✓ | App ID |
| `--limit` | | Max results |
| `--output` | | `json` (default) or `table` |
| `--pretty` | | Pretty-print JSON |

```bash
asc iap list --app-id A123
asc iap list --app-id A123 --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "createLocalization": "asc iap-localizations create --iap-id iap-1 --locale en-US --name <name>",
        "listLocalizations": "asc iap-localizations list --iap-id iap-1"
      },
      "appId": "A123",
      "id": "iap-1",
      "productId": "com.app.goldcoins",
      "referenceName": "Gold Coins",
      "state": "MISSING_METADATA",
      "type": "CONSUMABLE"
    }
  ]
}
```

---

### `asc iap create`

Create a new in-app purchase.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | ✓ | App ID |
| `--reference-name` | ✓ | Internal name (not shown to users) |
| `--product-id` | ✓ | Product ID (e.g. `com.app.goldcoins`) |
| `--type` | ✓ | `consumable`, `non-consumable`, `non-renewing-subscription` |

```bash
asc iap create --app-id A123 --reference-name "Gold Coins" --product-id "com.app.goldcoins" --type consumable
```

---

### `asc iap-localizations list`

List localizations for an in-app purchase.

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | ✓ | IAP ID |

```bash
asc iap-localizations list --iap-id iap-1
```

---

### `asc iap-localizations create`

Create a per-locale name and description for an IAP.

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | ✓ | IAP ID |
| `--locale` | ✓ | Locale code (e.g. `en-US`, `zh-Hans`) |
| `--name` | ✓ | Display name shown to users |
| `--description` | | Optional description |

```bash
asc iap-localizations create --iap-id iap-1 --locale en-US --name "Gold Coins" --description "In-game currency"
asc iap-localizations create --iap-id iap-1 --locale zh-Hans --name "金币"
```

---

### `asc iap submit`

Submit an in-app purchase for App Store review.

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | ✓ | IAP ID |

```bash
asc iap submit --iap-id iap-1
```

---

### `asc iap price-points list`

List available price points for an in-app purchase, optionally filtered by territory.

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | ✓ | IAP ID |
| `--territory` | | Filter by territory code (e.g. `USA`) |
| `--output` | | `json` (default) or `table` |
| `--pretty` | | Pretty-print JSON |

```bash
asc iap price-points list --iap-id iap-1
asc iap price-points list --iap-id iap-1 --territory USA --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "listPricePoints": "asc iap price-points list --iap-id iap-1",
        "setPrice": "asc iap prices set --iap-id iap-1 --base-territory USA --price-point-id pp-tier1"
      },
      "customerPrice": "0.99",
      "iapId": "iap-1",
      "id": "pp-tier1",
      "proceeds": "0.70",
      "territory": "USA"
    }
  ]
}
```

---

### `asc iap prices set`

Set the price schedule for an in-app purchase (base territory + auto-pricing for all other territories).

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | ✓ | IAP ID |
| `--base-territory` | ✓ | Base territory code (e.g. `USA`) |
| `--price-point-id` | ✓ | Price point ID from `asc iap price-points list` |

```bash
PRICE_ID=$(asc iap price-points list --iap-id iap-1 --territory USA \
  | jq -r '.data[] | select(.customerPrice == "0.99") | .id')
asc iap prices set --iap-id iap-1 --base-territory USA --price-point-id "$PRICE_ID"
```

---

### `asc subscription-groups list`

List subscription groups for an app.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | ✓ | App ID |
| `--limit` | | Max results |

```bash
asc subscription-groups list --app-id A123
```

---

### `asc subscription-groups create`

Create a new subscription group.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | ✓ | App ID |
| `--reference-name` | ✓ | Internal reference name for the group |

```bash
asc subscription-groups create --app-id A123 --reference-name "Premium Plans"
```

---

### `asc subscriptions list`

List subscriptions in a group.

| Flag | Required | Description |
|------|----------|-------------|
| `--group-id` | ✓ | Subscription group ID |
| `--limit` | | Max results |

```bash
asc subscriptions list --group-id grp-1
```

---

### `asc subscriptions create`

Create a subscription tier within a group.

| Flag | Required | Description |
|------|----------|-------------|
| `--group-id` | ✓ | Subscription group ID |
| `--name` | ✓ | Display name |
| `--product-id` | ✓ | Product ID (e.g. `com.app.monthly`) |
| `--period` | ✓ | `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR` |
| `--family-sharable` | | Enable Family Sharing (flag) |
| `--group-level` | | Level for upgrade/downgrade ordering |

```bash
asc subscriptions create --group-id grp-1 --name "Monthly Premium" --product-id "com.app.monthly" --period ONE_MONTH
asc subscriptions create --group-id grp-1 --name "Annual Premium" --product-id "com.app.annual" --period ONE_YEAR --family-sharable --group-level 1
```

---

### `asc subscription-localizations list`

List localizations for a subscription.

| Flag | Required | Description |
|------|----------|-------------|
| `--subscription-id` | ✓ | Subscription ID |

```bash
asc subscription-localizations list --subscription-id sub-1
```

---

### `asc subscription-localizations create`

Create a per-locale name and description for a subscription.

| Flag | Required | Description |
|------|----------|-------------|
| `--subscription-id` | ✓ | Subscription ID |
| `--locale` | ✓ | Locale code |
| `--name` | ✓ | Display name in App Store |
| `--description` | | Optional description |

```bash
asc subscription-localizations create --subscription-id sub-1 --locale en-US --name "Monthly Premium" --description "Full access to all features"
```

---

## Typical Workflow

```bash
APP_ID="A123456789"

# 1. Create a consumable IAP
IAP_ID=$(asc iap create \
  --app-id "$APP_ID" \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable \
  | jq -r '.data[0].id')

# 2. Add localizations
asc iap-localizations create --iap-id "$IAP_ID" --locale en-US --name "Gold Coins" --description "In-game currency"
asc iap-localizations create --iap-id "$IAP_ID" --locale zh-Hans --name "金币" --description "游戏货币"

# 3. Set pricing (Tier 1 in USA, Apple auto-calculates other territories)
PRICE_ID=$(asc iap price-points list --iap-id "$IAP_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "0.99") | .id')
asc iap prices set --iap-id "$IAP_ID" --base-territory USA --price-point-id "$PRICE_ID"

# 4. Submit for review
asc iap submit --iap-id "$IAP_ID"

# 5. Create a subscription group
GROUP_ID=$(asc subscription-groups create \
  --app-id "$APP_ID" \
  --reference-name "Premium Plans" \
  | jq -r '.data[0].id')

# 4. Create subscription tiers
MONTHLY_ID=$(asc subscriptions create \
  --group-id "$GROUP_ID" \
  --name "Monthly Premium" \
  --product-id "com.app.monthly" \
  --period ONE_MONTH \
  --group-level 1 \
  | jq -r '.data[0].id')

ANNUAL_ID=$(asc subscriptions create \
  --group-id "$GROUP_ID" \
  --name "Annual Premium" \
  --product-id "com.app.annual" \
  --period ONE_YEAR \
  --family-sharable \
  --group-level 2 \
  | jq -r '.data[0].id')

# 5. Add subscription localizations
asc subscription-localizations create --subscription-id "$MONTHLY_ID" --locale en-US --name "Monthly Premium" --description "Full access, billed monthly"
asc subscription-localizations create --subscription-id "$ANNUAL_ID" --locale en-US --name "Annual Premium" --description "Full access, billed annually — save 30%"
```

---

## Architecture

```
ASCCommand                       Infrastructure                       Domain
────────────────────────────────────────────────────────────────────────────
IAPList / IAPCreate              SDKInAppPurchaseRepository           InAppPurchase
IAPSubmit                        SDKInAppPurchaseSubmissionRepository InAppPurchaseSubmission
IAPPricePointsList               SDKInAppPurchasePriceRepository      InAppPurchasePricePoint
IAPPricesSet                     SDKInAppPurchasePriceRepository      InAppPurchasePriceSchedule
IAPLocalizationsList/Create      SDKIAPLocalizationRepo               InAppPurchaseLocalization
SubscriptionGroupsList/Create    SDKSubscriptionGroupRepo             SubscriptionGroup
SubscriptionsList/Create         SDKSubscriptionRepository            Subscription
SubLocalizationsList/Create      SDKSubLocalizationRepo               SubscriptionLocalization
```

All Infrastructure repositories inject the parent ID from the request parameter since the ASC API does not return it in responses.

**API versions used:**
- List IAPs: `GET /v1/apps/{id}/inAppPurchasesV2` (SDK v1)
- Create IAP: `POST /v2/inAppPurchases` (SDK v2)
- List IAP localizations: `GET /v2/inAppPurchases/{id}/inAppPurchaseLocalizations` (SDK v2)
- Create IAP localization: `POST /v1/inAppPurchaseLocalizations` (SDK v1)
- Subscription groups: `GET/POST /v1/subscriptionGroups` (SDK v1)
- Subscriptions: `GET /v1/subscriptionGroups/{id}/subscriptions`, `POST /v1/subscriptions` (SDK v1)
- Subscription localizations: `GET /v1/subscriptions/{id}/subscriptionLocalizations`, `POST /v1/subscriptionLocalizations` (SDK v1)

---

## Domain Models

### `InAppPurchase`

```swift
public struct InAppPurchase: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let appId: String          // parent — injected by Infrastructure
    public let referenceName: String
    public let productId: String
    public let type: InAppPurchaseType
    public let state: InAppPurchaseState
}
```

**`InAppPurchaseType`** raw values: `CONSUMABLE`, `NON_CONSUMABLE`, `NON_RENEWING_SUBSCRIPTION`
CLI arguments: `consumable`, `non-consumable`, `non-renewing-subscription`

**`InAppPurchaseState`** semantic booleans:
- `isApproved` / `isLive` — `true` when `APPROVED`
- `isEditable` — `true` when `MISSING_METADATA`, `REJECTED`, or `DEVELOPER_ACTION_NEEDED`
- `isPendingReview` — `true` when `WAITING_FOR_REVIEW` or `IN_REVIEW`

**Affordances:** `listLocalizations`, `createLocalization`, `listPricePoints` (always); `submit` only when `state == .readyToSubmit`

---

### `InAppPurchaseSubmission`

```swift
public struct InAppPurchaseSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String          // parent — injected by Infrastructure
}
```

**Affordances:** `listLocalizations`

---

### `InAppPurchasePricePoint`

```swift
public struct InAppPurchasePricePoint: Sendable, Equatable, Identifiable {
    public let id: String
    public let iapId: String          // parent — injected by Infrastructure
    public let territory: String?     // omitted from JSON when nil
    public let customerPrice: String? // omitted from JSON when nil
    public let proceeds: String?      // omitted from JSON when nil
}
```

**Affordances:** `listPricePoints` (always); `setPrice` only when `territory != nil`

---

### `InAppPurchasePriceSchedule`

```swift
public struct InAppPurchasePriceSchedule: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String          // parent — injected by Infrastructure
}
```

**Affordances:** `listPricePoints`

---

### `InAppPurchaseLocalization`

```swift
public struct InAppPurchaseLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    public let iapId: String          // parent — injected by Infrastructure
    public let locale: String
    public let name: String?
    public let description: String?
    public let state: InAppPurchaseLocalizationState?
}
```

Nil fields are omitted from JSON (custom `Codable` with `encodeIfPresent`).

**Affordances:** `listSiblings`

---

### `SubscriptionGroup`

```swift
public struct SubscriptionGroup: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let appId: String          // parent — injected by Infrastructure
    public let referenceName: String
}
```

**Affordances:** `listSubscriptions`, `createSubscription`

---

### `Subscription`

```swift
public struct Subscription: Sendable, Equatable, Identifiable {
    public let id: String
    public let groupId: String        // parent — injected by Infrastructure
    public let name: String
    public let productId: String
    public let subscriptionPeriod: SubscriptionPeriod
    public let isFamilySharable: Bool
    public let state: SubscriptionState
    public let groupLevel: Int?       // omitted from JSON when nil
}
```

**`SubscriptionPeriod`** values: `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

**`SubscriptionState`** semantic booleans: same as `InAppPurchaseState`

**Affordances:** `listLocalizations`, `createLocalization`

---

### `SubscriptionLocalization`

```swift
public struct SubscriptionLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    public let subscriptionId: String  // parent — injected by Infrastructure
    public let locale: String
    public let name: String?
    public let description: String?
    public let state: SubscriptionLocalizationState?
}
```

Nil fields are omitted from JSON.

**Affordances:** `listSiblings`

---

## File Map

```
Sources/Domain/Apps/
├── InAppPurchases/
│   ├── InAppPurchase.swift
│   ├── InAppPurchaseRepository.swift
│   ├── InAppPurchaseSubmission.swift
│   ├── InAppPurchaseSubmissionRepository.swift
│   ├── InAppPurchasePricePoint.swift
│   ├── InAppPurchasePriceSchedule.swift
│   ├── InAppPurchasePriceRepository.swift
│   └── Localizations/
│       ├── InAppPurchaseLocalization.swift
│       └── InAppPurchaseLocalizationRepository.swift
└── Subscriptions/
    ├── SubscriptionGroup.swift
    ├── SubscriptionGroupRepository.swift
    ├── Subscription.swift
    ├── SubscriptionRepository.swift
    └── Localizations/
        ├── SubscriptionLocalization.swift
        └── SubscriptionLocalizationRepository.swift

Sources/Infrastructure/Apps/
├── InAppPurchases/
│   ├── SDKInAppPurchaseRepository.swift
│   ├── SDKInAppPurchaseSubmissionRepository.swift
│   ├── SDKInAppPurchasePriceRepository.swift
│   └── Localizations/
│       └── SDKInAppPurchaseLocalizationRepository.swift
└── Subscriptions/
    ├── SDKSubscriptionGroupRepository.swift
    ├── SDKSubscriptionRepository.swift
    └── Localizations/
        └── SDKSubscriptionLocalizationRepository.swift

Sources/ASCCommand/Commands/
├── IAP/
│   ├── IAPCommand.swift
│   ├── IAPList.swift
│   ├── IAPCreate.swift
│   ├── IAPSubmit.swift
│   ├── IAPPricePointsCommand.swift
│   ├── IAPPricePointsList.swift
│   ├── IAPPricesCommand.swift
│   └── IAPPricesSet.swift
├── IAPLocalizations/
│   ├── IAPLocalizationsCommand.swift
│   ├── IAPLocalizationsList.swift
│   └── IAPLocalizationsCreate.swift
├── SubscriptionGroups/
│   ├── SubscriptionGroupsCommand.swift
│   ├── SubscriptionGroupsList.swift
│   └── SubscriptionGroupsCreate.swift
├── Subscriptions/
│   ├── SubscriptionsCommand.swift
│   ├── SubscriptionsList.swift
│   └── SubscriptionsCreate.swift
└── SubscriptionLocalizations/
    ├── SubscriptionLocalizationsCommand.swift
    ├── SubscriptionLocalizationsList.swift
    └── SubscriptionLocalizationsCreate.swift
```

**Wiring files:**
| File | Change |
|------|--------|
| `Sources/ASCCommand/ASC.swift` | Register 6 new command groups |
| `Sources/ASCCommand/ClientProvider.swift` | 7 new factory methods |
| `Sources/Infrastructure/Client/ClientFactory.swift` | 7 new factory methods |

---

## API Reference

| Command | SDK Endpoint | SDK Version |
|---------|-------------|-------------|
| `iap list` | `APIEndpoint.v1.apps.id(appId).inAppPurchasesV2.get()` | v1 |
| `iap create` | `APIEndpoint.v2.inAppPurchases.post(InAppPurchaseV2CreateRequest)` | v2 |
| `iap submit` | `APIEndpoint.v1.inAppPurchaseSubmissions.post(InAppPurchaseSubmissionCreateRequest)` | v1 |
| `iap price-points list` | `APIEndpoint.v2.inAppPurchases.id(iapId).pricePoints.get()` | v2 |
| `iap prices set` | `APIEndpoint.v1.inAppPurchasePriceSchedules.post(InAppPurchasePriceScheduleCreateRequest)` | v1 |
| `iap-localizations list` | `APIEndpoint.v2.inAppPurchases.id(iapId).inAppPurchaseLocalizations.get()` | v2 |
| `iap-localizations create` | `APIEndpoint.v1.inAppPurchaseLocalizations.post(InAppPurchaseLocalizationCreateRequest)` | v1 |
| `subscription-groups list` | `APIEndpoint.v1.apps.id(appId).subscriptionGroups.get()` | v1 |
| `subscription-groups create` | `APIEndpoint.v1.subscriptionGroups.post(SubscriptionGroupCreateRequest)` | v1 |
| `subscriptions list` | `APIEndpoint.v1.subscriptionGroups.id(groupId).subscriptions.get()` | v1 |
| `subscriptions create` | `APIEndpoint.v1.subscriptions.post(SubscriptionCreateRequest)` | v1 |
| `subscription-localizations list` | `APIEndpoint.v1.subscriptions.id(subscriptionId).subscriptionLocalizations.get()` | v1 |
| `subscription-localizations create` | `APIEndpoint.v1.subscriptionLocalizations.post(SubscriptionLocalizationCreateRequest)` | v1 |

---

## Testing

```swift
// Domain test
@Test func `subscription group affordances include listSubscriptions`() {
    let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
    #expect(group.affordances["listSubscriptions"] == "asc subscriptions list --group-id grp-1")
}

// Command test
@Test func `listed subscriptions include groupId, period, state and affordances`() async throws {
    let mockRepo = MockSubscriptionRepository()
    given(mockRepo).listSubscriptions(groupId: .any, limit: .any)
        .willReturn(PaginatedResponse(data: [
            Subscription(id: "sub-1", groupId: "grp-1", name: "Monthly Premium",
                        productId: "com.app.monthly", subscriptionPeriod: .oneMonth,
                        isFamilySharable: false, state: .missingMetadata)
        ], nextCursor: nil))

    let cmd = try SubscriptionsList.parse(["--group-id", "grp-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : { ... },
          "groupId" : "grp-1",
          "id" : "sub-1",
          ...
        }
      ]
    }
    """)
}
```

```bash
swift test --filter 'IAPListTests|IAPCreateTests|IAPSubmitTests|IAPPricePointsListTests|IAPPricesSetTests|SubscriptionGroupsListTests|SubscriptionsListTests'
```

---

## Extending

Natural next steps:

**Subscription Introductory Offers** — `POST /v1/subscriptionIntroductoryOffers`:
```bash
asc subscription-offers create --subscription-id <id> --duration ONE_MONTH --mode PAY_UP_FRONT
```
