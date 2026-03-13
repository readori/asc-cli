# We Open-Sourced the CLI That Runs Our App Store Releases

We make AppNexus (https://appnexus.app): a native macOS and iOS app for managing everything on App Store Connect. Screenshots, TestFlight, metadata, reviews — all in one place, no browser required.

But building AppNexus taught us something quickly. A GUI is great for humans. It is terrible for automation.

Every release still meant manually triggering the right steps in the right order. CI pipelines couldn't talk to App Store Connect without brittle scripts. AI agents had no way to navigate our release workflow. We needed something scriptable, composable, and agent-ready.

So we built `asc` as our internal backbone. Today we are open-sourcing it.


## The Problem Every iOS Developer Knows

Managing an App Store release is not one task. It is twelve tasks that have to happen in the right order.

You create a version. You upload a build. You wait for processing. You link the build to the version. You update the "What's New" copy in every locale. You upload screenshots for every device size. You check readiness. You submit. You wait. You do it again next sprint.

The App Store Connect web UI makes each of these steps a separate click-through. Xcode Organizer only handles uploads. Fastlane helps but requires Ruby expertise and breaks on every major Xcode update. There is no single tool that covers the full pipeline cleanly.

That was the itch. `asc` is the scratch.


## What asc Does

asc covers the full release pipeline from a single binary.

Releases:

```bash
asc versions create --app-id $APP_ID --version 2.1.0 --platform ios
asc versions set-build --version-id $VER --build-id $BUILD
asc versions check-readiness --version-id $VER
asc versions submit --version-id $VER
```

Builds and TestFlight:

```bash
asc builds upload --app-id $APP_ID --file MyApp.ipa
asc builds add-beta-group --build-id $BUILD --beta-group-id $GROUP
asc testflight testers import --beta-group-id $GROUP --file testers.csv
```

Metadata and localizations:

```bash
asc version-localizations update --localization-id $LOC --whats-new "..."
asc app-info-localizations update --localization-id $LOC --subtitle "..."
```

AI-powered screenshots:

```bash
asc app-shots generate --plan plan.json --output-dir ./shots screenshots/*.png
asc app-shots translate --to zh --to ja --to fr
```

That last command is the one people do not expect. Point it at your plan file and raw screenshots. It calls Gemini to composite your device frames, headings, and backgrounds. Then it auto-translates the overlays into every locale you need. No Photoshop. No Figma handoff. No design contractor.

It also handles everything else: IAPs, subscriptions, introductory offers, bundle IDs, certificates, provisioning profiles, age ratings, review contact details, and a plugin system that fires events like `build.uploaded` and `version.submitted` into your own executables.


## The Architecture Decision We Are Most Proud Of

Every JSON response from `asc` includes an `affordances` field.

It is a map of ready-to-run CLI commands that reflect what is actually possible at the current state of that resource.

```json
{
  "id": "abc123",
  "state": "PREPARE_FOR_SUBMISSION",
  "affordances": {
    "submitForReview": "asc versions submit --version-id abc123",
    "checkReadiness": "asc versions check-readiness --version-id abc123",
    "listLocalizations": "asc version-localizations list --version-id abc123"
  }
}
```

We call this CAEOAS: Commands As the Engine Of Application State. It is our take on REST's HATEOAS principle, applied to a CLI.

The practical result: an AI agent can drive your entire App Store release pipeline without memorizing the command tree. Pipe `asc` output into Claude, tell it to "submit the build when it's ready," and it navigates the workflow on its own. The tool tells the agent what is possible at every step.

This is how we run automated release flows for AppNexus today. The CLI drives the release. The agent watches and intervenes when something needs a human decision.


## Why We Are Releasing This as Open Source

We built `asc` for ourselves. But the problem is not unique to us.

Every iOS and macOS team manages this same pipeline. Solo developers do it manually and lose hours every release. Small teams maintain fragile scripts that break. Larger teams pay for SaaS wrappers that abstract too much and cost too much. Nobody has a clean, composable, open tool that just works.

We would rather build this in public. The tool is better when more people use it and report issues. The AI agent use case especially benefits from community input as the way developers integrate LLMs into release workflows is still being figured out.

If you ship apps on the App Store, try it. If something is broken or missing, file an issue. If you want to contribute, PRs are open.

Install via Homebrew: brew install tddworks/tap/asccli

CLI: https://github.com/tddworks/asc-cli
App: https://appnexus.app
