<p align="center">
  <br />
  <samp>n o d a y s i d i a n</samp>
  <br />
  <br />
  <strong>Native macOS knowledge graph for Markdown notes.</strong>
  <br />
  <sub>Local-first. SwiftUI. Obsidian import. On-device semantic linking.</sub>
  <br />
  <br />
  <img src="https://img.shields.io/badge/Platform-macOS%2015%2B-black?style=flat-square&logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-6.2-orange?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Framework-SwiftUI-0A84FF?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/AI-Apple%20NaturalLanguage-5856D6?style=flat-square" alt="NaturalLanguage">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
  <br />
  <br />
  <a href="#download">Download</a> &middot; <a href="#features">Features</a> &middot; <a href="#architecture">Architecture</a> &middot; <a href="#build-from-source">Build</a>
  <br />
  <br />
</p>

---

## What is Nodaysidian?

Nodaysidian is a native macOS app for writing Markdown notes, importing Obsidian vaults, and exploring the result as a local knowledge graph.

It stores data locally with Core Data, parses `[[wiki-links]]`, computes semantic similarity on-device with Apple’s NaturalLanguage framework, and renders notes as an interactive SwiftUI graph. No accounts, no API keys, no cloud sync, no Electron runtime.

## Features

- **Markdown note workspace** — create, edit, save, delete, and search notes.
- **Obsidian vault import** — imports `.md` files and maps `[[wiki-links]]` into graph edges.
- **Semantic auto-links** — discovers related notes from local text embeddings and adds `semantic-similarity` edges.
- **Ripeness scoring** — ranks notes by age, content depth, and connection density so stale or under-connected notes stand out.
- **Interactive graph canvas** — pan, zoom, drag nodes, double-click notes, freeze or resume the force simulation.
- **Whiteboard mode** — canvases with select, rectangle, ellipse, arrow, text, pencil, undo, and redo.
- **Native macOS packaging** — Swift Package Manager build plus ad-hoc signed `.app` bundle.

## Download

Download the latest macOS build from the GitLab releases page:

[Download latest release](https://gitlab.com/NODAYSIDLE/nodaysidian/-/releases/latest)

Requirements:

- macOS 15.0 or newer
- Apple Silicon build is produced by default on Apple Silicon hosts

Install from the release build:

1. Download `Nodaysidian.dmg`.
2. Open the disk image.
3. Drag `Nodaysidian.app` into `/Applications`.
4. Launch Nodaysidian.

The release build is ad-hoc signed. On first launch, macOS may require approving the app from Privacy & Security if Gatekeeper blocks unsigned developer apps.

## Keyboard shortcuts

- `Cmd + N` — New note
- `Cmd + Shift + N` — New canvas
- `Cmd + Shift + I` — Import Obsidian vault
- `Cmd + Shift + R` — Run intelligence scan
- `Cmd + S` — Save note
- `Cmd + Z` / `Cmd + Shift + Z` — Whiteboard undo / redo
- `Delete` — Delete selected whiteboard element

## How it works

### Notes and persistence

Nodaysidian uses a programmatic Core Data model. Notes, graph edges, canvases, and whiteboard elements are persisted locally on the Mac.

### Obsidian import

The vault importer scans a selected directory for Markdown files, strips simple front matter, uses the file name or `title:` field as the note title, and turns matching `[[wiki-links]]` into graph edges.

### Intelligence pass

The intelligence cycle runs on launch and can be triggered manually. It:

1. Computes ripeness scores for notes.
2. Generates local NaturalLanguage embeddings for note content.
3. Compares note embeddings with cosine similarity.
4. Creates auto-discovered graph edges when similarity passes the threshold.

All of this happens on-device.

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

Tech stack:

- Swift 6.2
- SwiftUI
- Core Data
- NaturalLanguage / NLEmbedding
- Swift Package Manager
- macOS app bundle scripts with ad-hoc codesigning

## Build from source

```bash
git clone https://gitlab.com/NODAYSIDLE/nodaysidian.git
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

## Release verification

The release process verifies:

```bash
swift build -c release
SIGNING_MODE=adhoc Scripts/package_app.sh release
codesign --verify --deep --strict --verbose=2 Nodaysidian.app
hdiutil verify Nodaysidian.dmg
shasum -a 256 Nodaysidian.dmg Nodaysidian_*.tar.gz
```

There is currently no separate automated test target in `Tests/`; `swift test` confirms the package builds but exits with SwiftPM’s `no tests found` status.

## Privacy

Nodaysidian is local-first:

- no account system
- no telemetry
- no network API calls for AI
- no remote embedding provider
- imported notes stay on the local Mac

## License

MIT

---

<p align="center">
  Built by <a href="https://gitlab.com/NODAYSIDLE">NODAYSIDLE</a>
</p>
