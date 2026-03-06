<p align="center">
  <br />
  <br />
  <samp>n o d a y s i d i a n</samp>
  <br />
  <br />
  <strong>The knowledge graph that thinks while you write.</strong>
  <br />
  <sub>On-device AI. Zero cloud. Pure macOS native.</sub>
  <br />
  <br />
  <a href="#install">Install</a> &middot; <a href="#how-it-works">How It Works</a> &middot; <a href="#why-nodaysidian">Why nodaysidian</a> &middot; <a href="#workflow">Workflow</a>
  <br />
  <br />
</p>

---

## What is this?

nodaysidian is a native macOS knowledge graph app that **automatically discovers hidden connections** between your notes using on-device machine learning. Import your Obsidian vault or start fresh. The app builds a living, force-directed graph where nodes glow based on how ready they are for your attention.

No Electron. No browser tabs. No API keys. No subscriptions. Just `swift build` and go.

---

## The Problem

Every knowledge management tool makes *you* do the connecting. You write the note, you tag it, you link it, you review it. The graph view in tools like Obsidian is a beautiful screensaver that shows connections **you already made** — it never surfaces the ones you missed.

nodaysidian fixes this. It reads your notes, builds semantic embeddings on-device, and draws edges between notes that are **conceptually related but never linked**. It also tells you which notes are ripe for revisiting based on temporal decay curves, not arbitrary reminders.

---

<h2 id="why-nodaysidian">Why nodaysidian beats the alternatives</h2>

### vs. Obsidian

| | Obsidian | nodaysidian |
|---|---|---|
| **Graph intelligence** | Shows only manual `[[wiki-links]]` — no discovery | Auto-discovers semantic connections via NLEmbedding |
| **Graph performance** | Electron-based, unusable at 1000+ nodes | Native SwiftUI Canvas + Metal, smooth at scale with auto-cooling simulation |
| **Embedding quality** | Requires plugins + external API keys | Built-in sentence-level NLEmbedding (macOS 15+), zero config |
| **Privacy** | Plugin AI sends data to cloud APIs | Everything stays on your Mac. Period. |
| **Spaced repetition** | Manual review scheduling or plugin | Automatic ripeness scoring — notes glow when they need attention |
| **Runtime** | Electron (Chromium wrapper, ~300MB RAM idle) | Native macOS binary (~15MB, minimal memory) |
| **Whiteboard** | Excalidraw-inspired canvas via plugin | Built-in whiteboard with shapes, pencil, arrows, text, undo/redo |
| **Markdown** | Native | Full import compatibility |

### vs. Logseq

| | Logseq | nodaysidian |
|---|---|---|
| **Architecture** | Electron + ClojureScript | Native Swift, SwiftUI, Core Data |
| **AI features** | None built-in | On-device sentence embeddings + auto-edge discovery |
| **Graph view** | Block-level, cluttered | Note-level, force-directed with physics cooling + freeze toggle |
| **Performance** | Slow on large graphs | O(1) edge lookups, alpha-cooled simulation, auto-stops when stable |

### vs. Roam Research

| | Roam Research | nodaysidian |
|---|---|---|
| **Pricing** | $15/month ($180/year) | Free and open source |
| **Data ownership** | Cloud-hosted, their servers | Local-first, your filesystem |
| **AI** | None | On-device NLEmbedding + temporal ripeness |
| **Offline** | Limited | Fully offline, always |
| **Platform** | Web app | Native macOS |

### vs. Notion

| | Notion | nodaysidian |
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

Every note is converted into a high-dimensional vector using Apple's `NLEmbedding`. On macOS 15+, nodaysidian uses **sentence-level embeddings** for dramatically better document similarity (falls back to word-level on older systems). Notes with cosine similarity above 0.65 get automatically connected. You write about "machine learning" in one note and "neural networks" in another — nodaysidian draws the edge for you.

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
Cmd + Shift + N    Create a new canvas
```

### 2. Write

The editor is clean and focused. Title field at the top, markdown body below. Toggle the metadata panel with the sidebar icon to see word count, timestamps, source path, and the ripeness bar.

```
Cmd + S            Save
Enter (in title)   Jump to body
```

### 3. Explore the graph

Switch to the graph view using the segmented toolbar. Your notes are alive:

- **Hover** a node to see its title
- **Click** to select and highlight
- **Double-click** a node to open it in the editor
- **Drag** nodes to rearrange the layout
- **Pinch** to zoom, **drag** empty space to pan
- **Freeze/Resume** simulation via the status bar toggle
- Mint edges = your manual links. Lavender edges = AI-discovered connections.

The simulation uses **alpha cooling** — it starts energetic and gradually settles, then auto-stops to save CPU. Click "frozen" in the status bar to re-energize the layout at any time.

### 4. Sketch on the whiteboard

```
Cmd + Shift + N    Create a new canvas
Cmd + Z            Undo
Cmd + Shift + Z    Redo
Delete             Remove selected element
```

Six drawing tools: Select, Rectangle, Ellipse, Arrow, Text, and Pencil. Full color picker, fill toggle, and stroke width control.

### 5. Let the AI work

```
Cmd + Shift + R    Run intelligence scan
```

This computes embeddings, discovers auto-edges, and updates ripeness scores. Also runs automatically on launch.

---

<h2 id="install">Install</h2>

### Requirements

- macOS 15.0+
- Swift 6.2+ (included with Xcode 26+)

### Build and install

```bash
git clone https://github.com/salvadalba/nodaysidle-nodaysidian.git
cd nodaysidle-nodaysidian

# Build + install to /Applications + launch
bash Scripts/install.sh

# Or just build
swift build -c release
```

---

## Architecture

```
Sources/NodaysIdle/
  App/              App entry point, intelligence cycle, error recovery UI
  Models/           Core Data (programmatic model), vault importer
  Views/
    GraphCanvas/    Force-directed graph with Canvas + SwiftUI overlay
    Sidebar/        Note list, search, canvas list, logotype header
    Editor/         Note editor with metadata panel + ripeness bar
    Whiteboard/     Excalidraw-inspired canvas with 6 tools + undo/redo
    Components/     Ripeness indicator, shared components
  ViewModels/       Graph simulation (cooled), vault state, whiteboard state
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
| UI | SwiftUI 6 (Canvas, NavigationSplitView, spring animations, segmented toolbar) |
| Data | Core Data (programmatic NSManagedObjectModel, no .xcdatamodeld) |
| Intelligence | NaturalLanguage framework (NLEmbedding — sentence-level on macOS 15+, word-level fallback) |
| Concurrency | Swift actors for thread-safe intelligence processing |
| Build | Swift Package Manager (no Xcode project required) |
| Packaging | Shell scripts (ad-hoc codesign, iconutil) |

---

## What's New (v0.2)

### Critical fixes
- **No more crash on corrupt data store** — graceful error view with recovery guidance instead of `fatalError`
- **Graph simulation cooling** — alpha decays over ~17 seconds, auto-stops when stable (saves CPU/battery)
- **O(1) graph edge lookups** — replaced O(n²) linear scans with UUID index dictionary
- **All Core Data saves are now error-logged** — silent `try?` replaced with `do/try/catch` + `[nodaysidian]` prefixed logging

### Graph improvements
- Pan and zoom now accumulate correctly across gestures (no more snapping to origin)
- Double-click a node to open the note in editor
- Freeze/Resume toggle in graph status bar
- Node positions auto-saved when simulation stops

### Editor & sidebar
- Sidebar note click always navigates to editor (fixed silent failure in graph mode)
- Delete note shows confirmation dialog before destroying data
- Canvas section hides when no canvases exist
- Import message auto-clears after 5 seconds
- Word count uses proper whitespace splitting (handles CJK, empty notes)
- Double-tap/single-tap gesture ordering fixed for canvas rename

### Whiteboard
- Cmd+Z and Cmd+Shift+Z now trigger undo/redo
- `createCanvas()` returns the new canvas directly (no fragile `.first` hack)

### Intelligence
- **Sentence-level embeddings** (macOS 15+) for dramatically better document similarity
- Falls back to word-level embeddings on older systems

### UI polish
- Toolbar mode buttons now show active-state pill background
- "NODAYSIDLE" branding updated to "nodaysidian" throughout the app
- Accessibility labels on ripeness dots, graph nodes, and toolbar buttons

---

## Design Philosophy

- **Flat, not flashy.** No gradients. Solid colors, crisp 1px borders, intentional typography.
- **Intelligence, not decoration.** The graph isn't eye candy — every edge means something.
- **Local-first, always.** Your notes never leave your machine. No accounts, no sync servers, no telemetry.
- **Markdown native.** Import from Obsidian. Zero lock-in.

---

## Roadmap

- [ ] Backlinks panel (show which notes link to the current note)
- [ ] `[[wiki-link]]` autocomplete in editor
- [ ] Quick switcher (Cmd+O) for keyboard-driven note navigation
- [ ] Markdown preview / live rendering toggle
- [ ] Core ML custom model for personalized ripeness prediction
- [ ] Multi-vault support
- [ ] Tags and folders for organizational hierarchy
- [ ] Export to Obsidian-compatible vault
- [ ] Search within note content with highlighting
- [ ] Multi-window / split pane support
- [ ] Light mode / system color scheme following
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
