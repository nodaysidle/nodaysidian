<img src=".github/social-preview.png" alt="Nodaysidian — NODAYSIDLE" width="100%">

# Nodaysidian

> Native macOS knowledge graph for Markdown notes.

Local-first. SwiftUI. Obsidian import. On-device semantic linking.

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.2-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-6-0A84FF?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

## Overview

Nodaysidian is a native macOS app for writing Markdown notes, importing Obsidian vaults, and exploring the result as a local knowledge graph. It stores data locally with Core Data, parses `[[wiki-links]]`, computes semantic similarity on-device with Apple's NaturalLanguage framework, and renders notes as an interactive SwiftUI graph. No accounts, no API keys, no cloud sync, no Electron.

## Features

- **Markdown note workspace** — create, edit, save, delete, and search notes
- **Obsidian vault import** — imports `.md` files and maps `[[wiki-links]]` into graph edges
- **Semantic auto-links** — discovers related notes from local text embeddings and adds `semantic-similarity` edges
- **Ripeness scoring** — ranks notes by age, content depth, and connection density
- **Interactive graph canvas** — pan, zoom, drag nodes, double-click notes, freeze or resume force simulation
- **Whiteboard mode** — canvases with select, rectangle, ellipse, arrow, text, pencil, undo, and redo
- **Native macOS packaging** — Swift Package Manager build plus ad-hoc signed `.app` bundle

## Technology

| Area | Technology |
|------|------------|
| Language | Swift 6.2 |
| Interface | SwiftUI |
| Data | Core Data |
| Intelligence | NaturalLanguage / NLEmbedding (on-device) |
| Build | Swift Package Manager |

## Installation

Download the latest macOS build from [GitHub Releases](https://github.com/nodaysidle/nodaysidian/releases/latest).

Requirements:

- macOS 15.0 or later
- Apple Silicon build is produced by default on Apple Silicon hosts

1. Download `Nodaysidian.dmg`
2. Open the disk image
3. Drag `Nodaysidian.app` into `/Applications`
4. Launch Nodaysidian

The release build is ad-hoc signed. On first launch, macOS may require approval from Privacy & Security.

## Keyboard Shortcuts

- `Cmd + N` — New note
- `Cmd + Shift + N` — New canvas
- `Cmd + Shift + I` — Import Obsidian vault
- `Cmd + Shift + R` — Run intelligence scan
- `Cmd + S` — Save note
- `Cmd + Z` / `Cmd + Shift + Z` — Whiteboard undo / redo
- `Delete` — Delete selected whiteboard element

## How It Works

### Notes and persistence

Nodaysidian uses a programmatic Core Data model. Notes, graph edges, canvases, and whiteboard elements are persisted locally.

### Obsidian import

The vault importer scans a selected directory for Markdown files, strips simple front matter, uses the file name or `title:` field as the note title, and turns matching `[[wiki-links]]` into graph edges.

### Intelligence pass

The intelligence cycle runs on launch and can be triggered manually. It computes ripeness scores, generates local NaturalLanguage embeddings, compares note embeddings with cosine similarity, and creates auto-discovered graph edges when similarity passes the threshold. All on-device.

## Development

```bash
git clone https://github.com/nodaysidle/nodaysidian.git
cd nodaysidian
swift build -c release
```

Build the app bundle:

```bash
SIGNING_MODE=adhoc Scripts/package_app.sh release
codesign --verify --deep --strict --verbose=2 Nodaysidian.app
```

Install locally:

```bash
bash Scripts/install.sh
```

## Architecture

```text
Sources/NodaysIdle/
  App/              App entry point, commands, launch-time intelligence pass
  Models/           Core Data model, entity helpers, Obsidian vault importer
  Intelligence/     Embedding, auto-edge discovery, ripeness scoring
  ViewModels/       Vault, graph simulation, whiteboard state
  Views/            Main shell, sidebar, editor, graph canvas, whiteboard
  Theme/            Dark theme, color system, typography, shared modifiers
Scripts/
  package_app.sh    Build and bundle Nodaysidian.app
  build-dmg.sh      Build a drag-to-Applications DMG
  install.sh        Build, install to /Applications, and launch
  compile_and_run.sh  Local development build-and-run loop
  generate_icon.sh  Generate Icon.icns from SVG source
```

## Release Verification

```bash
swift build -c release
SIGNING_MODE=adhoc Scripts/package_app.sh release
codesign --verify --deep --strict --verbose=2 Nodaysidian.app
hdiutil verify Nodaysidian.dmg
shasum -a 256 Nodaysidian.dmg Nodaysidian_*.tar.gz
```

## Privacy

Nodaysidian is local-first: no account system, no telemetry, no network API calls for AI, no remote embedding provider. Imported notes stay on the local Mac.

## Status

Active — feature-complete knowledge graph app. Ad-hoc signed, not notarized.

## Contributing

This repository is not currently accepting external contributions.

## License

MIT
