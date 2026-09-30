# AGENTS.md

Instructions for coding agents working in this repository.

## What this project is

Lucid is a macOS menu bar app that keeps the Mac awake, inspired by the GNOME Shell [Caffeine](https://extensions.gnome.org/extension/517/caffeine/) extension. See `README.md` for the full picture before making changes — it explains the intent behind the name and the project structure.

## Build & test

Always use `xcodebuild` from the repo root (no CocoaPods/SPM dependencies to resolve):

```sh
# Build
xcodebuild -project Lucid.xcodeproj -scheme Lucid -destination 'platform=macOS' build

# Run the full test suite
xcodebuild test -project Lucid.xcodeproj -scheme Lucid -destination 'platform=macOS'

# Run a single test target/class
xcodebuild test -project Lucid.xcodeproj -scheme Lucid -destination 'platform=macOS' -only-testing:LucidTests/StateManagerTests
```

A change is not done until `xcodebuild test` passes. Don't rely on SourceKit/editor diagnostics alone — they lag behind real compiler state in this environment; always confirm with an actual build.

## Test-driven development is mandatory

For any new logic, bug fix, or behavioral change:

1. Write a failing test first.
2. Run it and confirm it fails for the expected reason (not a typo or setup error).
3. Write the minimum code to make it pass.
4. Refactor while keeping tests green.

For pure refactors (no behavior change), make sure existing tests still pass; add coverage only if it's missing. For non-logic changes (docs, formatting, asset tweaks), tests aren't required.

`StateManager` is the reference example: it depends on the `PowerAssertionService` protocol instead of calling IOKit directly, so its activate/deactivate/toggle logic is fully testable with a mock (`LucidTests/StateManagerTests.swift`) without touching real system sleep state. Follow this pattern — anything that talks to a system API (IOKit, file system, network) should sit behind a small protocol so the logic around it stays testable.

## Project structure

```
Lucid/
├── LucidApp.swift              # App entry point, wires the menu bar scene
├── StateManager.swift          # Owns app state, drives the power assertion lifecycle
├── PowerAssertionService.swift # IOKit wrapper behind a protocol, for testability
├── MenuBarContentView.swift    # The popup menu UI
├── Localizable.xcstrings       # String catalog (en, pt-BR)
├── LucidIcon.icon               # App icon, authored with Icon Composer
└── Assets.xcassets

LucidTests/       # Unit tests (Swift Testing framework, not XCTest)
LucidUITests/     # UI tests
```

`Lucid/`, `LucidTests/`, and `LucidUITests/` are Xcode **synchronized groups**: any file you add on disk inside these folders is automatically picked up as a target member — you never need to touch `project.pbxproj` to add a Swift file. You only need to edit `project.pbxproj` directly for project-level settings (build settings, `knownRegions`, target config), and even then, prefer doing so surgically.

## Conventions to follow

- **Swift Testing, not XCTest.** New tests use `import Testing` and `@Test func ...` / `#expect(...)`, matching the existing test files.
- **`@Observable`, not `ObservableObject`.** State-holding reference types use the `Observation` framework's `@Observable` macro (see `StateManager`), consistent with the macOS 26 deployment target.
- **Localize user-facing strings.** Any text shown in the UI goes through `Lucid/Localizable.xcstrings` with both `en` and `pt-BR` entries — never hardcode a literal string in a `Text`/`Button` label. Diagnostic/internal strings (e.g. the IOKit assertion reason) don't need localization.
- **Menu bar UI, not a custom window.** The popup is a native `MenuBarExtra` menu (`.menu` style), which macOS 26 already renders with Liquid Glass automatically. Don't introduce a custom `.window`-style popup or manual glass effects unless explicitly asked — that's a deliberate architectural choice, not an oversight.

## Release process

Use the `release` skill (`.claude/skills/release/SKILL.md`) — invoked via `/release` — which covers how CI builds and ships a release and the tap-update mechanics.

## General engineering rules

- Make surgical changes: touch only what the task requires, match existing style, don't refactor unrelated code.
- Don't add error handling, abstractions, or configurability that isn't needed for the task at hand.
- Before any destructive git operation (`reset --hard`, `checkout` over uncommitted changes, force push), check `git status` first and stop if there's uncommitted work that isn't yours to discard.
- Verify UI-affecting changes by actually building and running the app (`open` the built `.app` from `DerivedData`), not just by reading the code — this project has caught real bugs (e.g. missing IOKit imports, stale state after toggling) this way.
