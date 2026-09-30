<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Lucid icon">
</p>

<h1 align="center">Lucid</h1>

<p align="center">
  Keep your Mac awake, on purpose.
</p>

## About

Lucid is a lightweight macOS menu bar utility that prevents your Mac from going to sleep — inspired by the GNOME Shell extension [Caffeine](https://extensions.gnome.org/extension/517/caffeine/), brought to macOS.

The name is a nod to *lucidity*: a system that's fully awake and aware, ready for whatever you're doing, instead of dozing off mid-task. It lives quietly in the menu bar.

### Core mechanism

- Adds a menu bar icon that toggles between **active** (keeping the Mac awake) and **inactive**.
- Uses the IOKit power management APIs (`IOPMAssertionCreateWithName`) to create a real system-level "prevent idle sleep" assertion — the same mechanism tools like Caffeine and Amphetamine rely on.
- Releases the assertion when deactivated; the system also releases it automatically if the app quits.
- Localized in English and Brazilian Portuguese.

## Requirements

- macOS 27 or later
- Xcode 27 or later

## Getting started

1. Clone the repository.
2. Open `Lucid.xcodeproj` in Xcode.
3. Select the `Lucid` scheme and run (`⌘R`).

Lucid is a menu bar–only app (`LSUIElement`), so it won't show up in the Dock — look for its icon in the menu bar after launching.

## Project structure

```
Lucid/
├── LucidApp.swift              # App entry point, wires the menu bar scene
├── StateManager.swift          # Owns app state, drives the power assertion lifecycle
├── PowerAssertionService.swift # IOKit wrapper behind a protocol, for testability
├── MenuBarContentView.swift    # The popup menu UI
├── Localizable.xcstrings       # String catalog (en, pt-BR)
├── LucidIcon.icon               # App icon, built with Icon Composer
└── Assets.xcassets

LucidTests/       # Unit tests (Swift Testing)
LucidUITests/     # UI tests
```

## Development

This project follows a test-driven workflow for application logic. `StateManager` is decoupled from the real IOKit calls through the `PowerAssertionService` protocol, so its activate/deactivate/toggle behavior is fully covered by unit tests without touching the actual system sleep state.

Run the full test suite from the command line:

```sh
xcodebuild test -project Lucid.xcodeproj -scheme Lucid -destination 'platform=macOS'
```

Or run tests directly from Xcode with `⌘U`.

### Localization

User-facing strings live in `Lucid/Localizable.xcstrings` (English and Brazilian Portuguese). Add new keys there and reference them by key in SwiftUI views — Xcode's String Catalog editor handles the rest.

### App icon

The app icon is authored with [Icon Composer](https://developer.apple.com/icon-composer/) and lives at `Lucid/LucidIcon.icon`. Open it directly in Icon Composer to edit.
