<p align="center">
  <br />
  <br />
  <samp>N O D A Y S I D L E</samp>
  <br />
  <br />
  <strong>The knowledge graph that thinks while you write.</strong>
  <br />
  <sub>On-device AI. Zero cloud. Pure macOS native.</sub>
  <br />
  <br />
  <a href="#install">Install</a> &middot; <a href="#how-it-works">How It Works</a> &middot; <a href="#why-nodaysidle">Why NODAYSIDLE</a> &middot; <a href="#workflow">Workflow</a>
  <br />
  <br />
</p>

---

## What is this?

NODAYSIDIAN is a native macOS knowledge graph app that **automatically discovers hidden connections** between your notes using on-device machine learning. Import your Obsidian vault or start fresh. The app builds a living, force-directed graph where nodes glow based on how ready they are for your attention.

No Electron. No browser tabs. No API keys. No subscriptions. Just `swift build` and go.

---

## The Problem

Every knowledge management tool makes *you* do the connecting. You write the note, you tag it, you link it, you review it. The graph view in tools like Obsidian is a beautiful screensaver that shows connections **you already made** — it never surfaces the ones you missed.

NODAYSIDLE fixes this. It reads your notes, builds semantic embeddings on-device, and draws edges between notes that are **conceptually related but never linked**. It also tells you which notes are ripe for revisiting based on temporal decay curves, not arbitrary reminders.

---

<h2 id="why-nodaysidle">Why NODAYSIDLE beats the alternatives</h2>

### vs. Obsidian

| | Obsidian | NODAYSIDLE |
|---|---|---|
| **Graph intelligence** | Shows only manual `[[wiki-links]]` — no discovery | Auto-discovers semantic connections via NLEmbedding |
| **Graph performance** | Electron-based, unusable at 1000+ nodes ([community reports](https://forum.obsidian.md/t/obsidian-graph-view-doesnt-work-for-a-large-vault/106287)) | Native SwiftUI Canvas + Metal rendering, smooth at scale |
| **On-device AI** | Requires plugins + external API keys (OpenAI, etc.) | Built-in NLEmbedding, zero config, zero cost |
| **Privacy** | Plugin AI sends data to cloud APIs | Everything stays on your Mac. Period. |
| **Spaced repetition** | Manual review scheduling or plugin | Automatic ripeness scoring — notes glow when they need attention |
| **Runtime** | Electron (Chromium wrapper, ~300MB RAM idle) | Native macOS binary (~15MB, minimal memory) |
| **Markdown** | Native | Full import/export compatibility |

### vs. Logseq

| | Logseq | NODAYSIDLE |
|---|---|---|
| **Architecture** | Electron + ClojureScript | Native Swift, SwiftUI, Core Data |
| **AI features** | None built-in | On-device embeddings + auto-edge discovery |
| **Graph view** | Block-level, cluttered | Note-level, force-directed with physics simulation |
| **Performance** | Slow on large graphs | 60fps force simulation via native rendering |

### vs. Roam Research

| | Roam Research | NODAYSIDLE |
|---|---|---|
| **Pricing** | $15/month ($180/year) | Free and open source |
| **Data ownership** | Cloud-hosted, their servers | Local-first, your filesystem |
| **AI** | None | On-device NLEmbedding + temporal ripeness |
| **Offline** | Limited | Fully offline, always |
| **Platform** | Web app | Native macOS |

### vs. Notion

| | Notion | NODAYSIDLE |
|---|---|---|
| **Purpose** | General productivity (docs, tasks, wikis) | Purpose-built knowledge graph with AI |
| **Graph view** | None | Force-directed with semantic auto-linking |
| **Speed** | Slow (web-based, server roundtrips) | Instant (local Core Data, no network) |
| **AI** | Cloud-based, $10/month add-on | On-device, free, private |
| **Offline** | Partial, unreliable | Complete |

---

<h2 id="how-it-works">How It Works</h2>

### Three intelligence systems, all on-device

**1. Semantic Embedding Engine**

Every note is converted into a 512-dimensional vector using Apple's `NLEmbedding` (Natural Language framework). Notes with cosine similarity above 0.65 get automatically connected. You write about "machine learning" in one note and "neural networks" in another — NODAYSIDLE draws the edge for you.

**2. Temporal Ripeness Regressor**

Each note gets a ripeness score (0–100%) computed from:
- **Time decay** — bell curve peaking at 7–14 days (the spaced repetition sweet spot)
- **Connection density** — isolated notes with few edges score higher (they need bridging)
- **Content depth** — longer, richer notes have more latent connection potential

Nodes glow by ripeness tier:

| Score | Color | Label | Meaning |
|---|---|---|---|
| 0–29% | Gray | Seedling | Fresh, no action needed |
| 30–59% | Mint | Growing | Building connections |
| 60–84% | Amber | Maturing | Worth revisiting soon |
| 85–100% | Coral | Ripe | Ready for attention now |

**3. Auto-Edge Discovery**

The embedding engine runs pairwise similarity across all notes and creates edges labeled `semantic-similarity` when the threshold is met. These appear as lavender lines in the graph — distinct from your manual wiki-links (shown in mint).

---

<h2 id="workflow">Workflow</h2>

### 1. Import or create

```
Cmd + Shift + I    Import an Obsidian vault (reads .md + [[wiki-links]])
Cmd + N            Create a new note
```

### 2. Write

The editor is clean and focused. Title field at the top, markdown body below. Toggle the metadata panel with the sidebar icon to see word count, timestamps, source path, and the ripeness bar.

```
Cmd + S            Save
Enter (in title)   Jump to body
```

### 3. Explore

Switch to the graph view with the toolbar toggle. Your notes are alive:

- **Hover** a node to see its title
- **Click** to select and open in editor
- **Drag** nodes to rearrange the layout
- **Pinch** to zoom, **drag** empty space to pan
- Mint edges = your manual links. Lavender edges = AI-discovered connections.

### 4. Let the AI work

```
Cmd + Shift + R    Run intelligence scan
```

This computes embeddings, discovers auto-edges, and updates ripeness scores. Also runs automatically on launch.

---

<h2 id="install">Install</h2>

### Requirements

- macOS 15.0+
- Swift 6.2+ (included with Xcode 26+)

### Build and run

```bash
git clone https://github.com/salvadalba/nodaysidle-nodaysidian.git
cd nodaysidle-nodaysidian

# Build and launch
bash Scripts/compile_and_run.sh

# Or install to /Applications
bash Scripts/install.sh
```

### Just build

```bash
swift build -c release
```

---

## Architecture

```
Sources/NodaysIdle/
  App/              App entry point, intelligence cycle runner
  Models/           Core Data (programmatic model), vault importer
  Views/
    GraphCanvas/    Force-directed graph with Canvas + SwiftUI overlay
    Sidebar/        Note list, search, logotype header
    Editor/         Note editor with metadata panel
    Components/     Ripeness indicator, shared components
  ViewModels/       Graph simulation, vault state management
  Intelligence/     NLEmbedding engine, ripeness scoring, auto-edge discovery
  Theme/            Color system, typography ladder, card modifiers
Scripts/
  package_app.sh    Build + bundle into .app
  compile_and_run.sh  Kill, build, launch (dev loop)
  install.sh        Build + copy to /Applications
  generate_icon.sh  SVG → icns icon generation
```

### Tech stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 6 (Canvas, NavigationSplitView, spring animations) |
| Data | Core Data (programmatic NSManagedObjectModel, no .xcdatamodeld) |
| Intelligence | NaturalLanguage framework (NLEmbedding, 512-dim word vectors) |
| Build | Swift Package Manager (no Xcode project required) |
| Packaging | Shell scripts (ad-hoc codesign, iconutil) |

---

## Design Philosophy

- **Flat, not flashy.** No gradients. Solid colors, crisp 1px borders, intentional typography.
- **Intelligence, not decoration.** The graph isn't eye candy — every edge means something.
- **Local-first, always.** Your notes never leave your machine. No accounts, no sync servers, no telemetry.
- **Markdown native.** Import from Obsidian. Export back anytime. Zero lock-in.

---

## Roadmap

- [ ] Sentence-level embedding (NLEmbedding.sentenceEmbedding) for deeper similarity
- [ ] Core ML custom model for personalized ripeness prediction
- [ ] Multi-vault support
- [ ] Markdown preview rendering
- [ ] Keyboard-driven graph navigation
- [ ] Export to Obsidian-compatible vault
- [ ] Tag clustering and automatic topic groups

---

## License

MIT

---

<p align="center">
  <sub>Built with Swift, SwiftUI, Core Data, and NaturalLanguage.</sub>
  <br />
  <sub>No Electron was harmed in the making of this app.</sub>
</p>
