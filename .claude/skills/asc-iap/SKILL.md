---
name: asc-iap
description: |
  Manage In-App Purchases (IAPs) and auto-renewable subscriptions using the `asc` CLI tool.
  Use this skill when:
  (1) Listing IAPs for an app: "asc iap list --app-id ID"
  (2) Creating an IAP: "asc iap create --app-id ID --type consumable|non-consumable|non-renewing-subscription"
  (3) Adding IAP localizations: "asc iap-localizations create --iap-id ID --locale en-US --name 'Gold Coins'"
  (4) Creating subscription groups: "asc subscription-groups create --app-id ID --reference-name 'Premium'"
  (5) Creating subscriptions: "asc subscriptions create --group-id ID --period ONE_MONTH"
  (6) Adding subscription localizations: "asc subscription-localizations create --subscription-id ID --locale en-US --name 'Monthly'"
  (7) User says "set up IAP", "create in-app purchase", "add subscription tier", "manage subscriptions", "localize IAP"
---

# asc In-App Purchases & Subscriptions

Manage IAPs and auto-renewable subscriptions via the `asc` CLI.

## In-App Purchases

### List IAPs

```bash
asc iap list --app-id <APP_ID> [--limit N] [--pretty]
```

### Create IAP

```bash
asc iap create \
  --app-id <APP_ID> \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable
```

**`--type`** values: `consumable`, `non-consumable`, `non-renewing-subscription`

### IAP Localizations

```bash
# List
asc iap-localizations list --iap-id <IAP_ID>

# Create
asc iap-localizations create \
  --iap-id <IAP_ID> \
  --locale en-US \
  --name "Gold Coins" \
  [--description "In-game currency"]
```

## Subscription Groups

```bash
# List
asc subscription-groups list --app-id <APP_ID>

# Create
asc subscription-groups create \
  --app-id <APP_ID> \
  --reference-name "Premium Plans"
```

## Subscriptions

```bash
# List
asc subscriptions list --group-id <GROUP_ID>

# Create
asc subscriptions create \
  --group-id <GROUP_ID> \
  --name "Monthly Premium" \
  --product-id "com.app.monthly" \
  --period ONE_MONTH \
  [--family-sharable] \
  [--group-level 1]
```

**`--period`** values: `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

### Subscription Localizations

```bash
# List
asc subscription-localizations list --subscription-id <SUBSCRIPTION_ID>

# Create
asc subscription-localizations create \
  --subscription-id <SUBSCRIPTION_ID> \
  --locale en-US \
  --name "Monthly Premium" \
  [--description "Full access, billed monthly"]
```

## CAEOAS Affordances

Every response embeds ready-to-run follow-up commands:

**IAP:**
```json
{
  "affordances": {
    "listLocalizations":  "asc iap-localizations list   --iap-id <ID>",
    "createLocalization": "asc iap-localizations create --iap-id <ID> --locale en-US --name <name>"
  }
}
```

**SubscriptionGroup:**
```json
{
  "affordances": {
    "listSubscriptions":  "asc subscriptions list   --group-id <ID>",
    "createSubscription": "asc subscriptions create --group-id <ID> --name <name> --product-id <id> --period ONE_MONTH"
  }
}
```

**Subscription:**
```json
{
  "affordances": {
    "listLocalizations":  "asc subscription-localizations list   --subscription-id <ID>",
    "createLocalization": "asc subscription-localizations create --subscription-id <ID> --locale en-US --name <name>"
  }
}
```

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
asc iap-localizations create --iap-id "$IAP_ID" --locale zh-Hans --name "金币"

# 3. Create a subscription group
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

## State Semantics

`InAppPurchaseState` and `SubscriptionState` expose semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

Nil optional fields (`description`, `state`, `groupLevel`) are omitted from JSON output.