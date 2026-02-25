---
name: asc-testflight
description: |
  Manage TestFlight beta groups and testers using the `asc` CLI tool.
  Use this skill when:
  (1) Listing beta groups for an app (`asc testflight groups list`)
  (2) Listing testers in a group (`asc testflight testers list --group-id <id>`)
  (3) Adding a single tester by email (`asc testflight testers add`)
  (4) Removing a tester from a group (`asc testflight testers remove`)
  (5) Bulk-importing testers from a CSV file (`asc testflight testers import`)
  (6) Exporting testers to CSV for re-use (`asc testflight testers export`)
  (7) User says "add beta tester", "invite tester", "remove tester", "import testers",
      "export testers", "list beta groups", or any TestFlight tester management task
---

# TestFlight Beta Tester Management with `asc`

Manage beta groups and testers for your TestFlight distribution.

## Authentication

Set up credentials before any TestFlight commands:
```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## CAEOAS — Affordances Guide Next Steps

Every JSON response includes `"affordances"` with ready-to-run commands:

**BetaGroup affordances:**
```json
{
  "id": "g-abc123",
  "appId": "6450406024",
  "name": "External Beta",
  "affordances": {
    "listTesters":   "asc testflight testers list   --group-id g-abc123",
    "importTesters": "asc testflight testers import --group-id g-abc123 --file testers.csv",
    "exportTesters": "asc testflight testers export --group-id g-abc123"
  }
}
```

**BetaTester affordances:**
```json
{
  "id": "t-xyz789",
  "groupId": "g-abc123",
  "email": "jane@example.com",
  "affordances": {
    "listSiblings": "asc testflight testers list   --group-id g-abc123",
    "remove":       "asc testflight testers remove --group-id g-abc123 --tester-id t-xyz789"
  }
}
```

Copy affordance commands directly — no need to look up IDs.

## Typical Workflow

```bash
# 1. Find beta groups for an app
asc testflight groups list --app-id 6450406024 --pretty

# 2. List testers in a group (copy affordance "listTesters" from step 1)
asc testflight testers list --group-id g-abc123 --pretty

# 3. Add a single tester
asc testflight testers add \
  --group-id g-abc123 \
  --email jane@example.com \
  --first-name Jane \
  --last-name Doe

# 4. Remove a tester (copy affordance "remove" from tester JSON)
asc testflight testers remove --group-id g-abc123 --tester-id t-xyz789

# 5. Bulk import from CSV (header row required: email,firstName,lastName)
asc testflight testers import --group-id g-abc123 --file testers.csv

# 6. Export to CSV (pipe to file or use redirect)
asc testflight testers export --group-id g-abc123 > testers.csv

# 7. Clone a group's testers to a new group
asc testflight testers export --group-id g-abc123 > testers.csv
asc testflight testers import --group-id g-new456 --file testers.csv
```

## CSV Format

Import/export CSV — header row required, `firstName` and `lastName` are optional:

```csv
email,firstName,lastName
jane@example.com,Jane,Doe
john@example.com,John,Smith
anon@example.com,,
```

## Output Flags

```bash
--pretty          # Pretty-print JSON
--output table    # Table format
--output markdown # Markdown table
```

## Full Command Reference

See [commands.md](references/commands.md) for all flags, filters, and examples.