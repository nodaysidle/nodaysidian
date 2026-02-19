# Whiteboard Feature Design — NODAYSIDLE

**Date:** 2026-02-19
**Status:** Approved

## Goal

Add an Excalidraw-inspired freeform whiteboard canvas to NODAYSIDLE. Start with a standalone whiteboard view (third view mode alongside Graph and Editor). Per-note embedded canvases planned for v2.

## Data Model

### CanvasEntity (Core Data, programmatic)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| title | String | Default: "Untitled Canvas" |
| elementsData | Binary | JSON-encoded [CanvasElement] |
| createdAt | Date | |
| modifiedAt | Date | |
| linkedNoteId | UUID? | nil for standalone, set for per-note (v2) |

### CanvasElement (Codable struct, stored as JSON in elementsData)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Element identity |
| type | CanvasElementType | rect, ellipse, line, arrow, text, pencil |
| frame | CGRect | Bounding box (x, y, width, height) |
| rotation | Double | Radians, default 0 |
| strokeColor | String | Hex color string |
| fillColor | String? | nil = no fill |
| strokeWidth | CGFloat | 1-6pt range |
| text | String? | For text elements |
| points | [CGPoint]? | For pencil/freehand and arrow paths |
| arrowHead | Bool | true for arrow, false for plain line |

## View Architecture

```
MainView toolbar adds: [Graph] [Editor] [Whiteboard]

WhiteboardView
├── Canvas (renders all elements)
├── SelectionOverlay (handles, resize corners)
├── FloatingTextField (inline text editing)
├── ToolbarStrip (bottom-center floating pill)
│   ├── Tool buttons: Select | Rect | Ellipse | Arrow | Text | Pencil
│   ├── ColorPicker (full spectrum, theme presets)
│   ├── Stroke/Fill toggle
│   └── Stroke width slider (1-6pt)
└── StatusBar (bottom-left, element count)
```

## Drawing Tools (v1)

| Tool | Drag | Click | Double-click |
|------|------|-------|--------------|
| Select | Move element / box-select | Select element | Edit text |
| Rect | Draw from corner to corner | — | — |
| Ellipse | Draw from corner to corner | — | — |
| Arrow/Line | Draw from start to end | — | — |
| Text | — | Place + open inline editor | — |
| Pencil | Freehand path | — | — |

## Keyboard Shortcuts

- `Delete` / `Backspace` — remove selected element
- `Cmd+Z` — undo
- `Cmd+Shift+Z` — redo
- `Cmd+A` — select all
- `Cmd+Shift+N` — new canvas
- Pan: drag empty space
- Zoom: pinch/scroll

## Color Picker

- Native macOS `ColorPicker` for full spectrum access
- Default palette preloaded with theme colors: mint, lavender, coral, amber, textPrimary, textMuted

## Canvas Management

- Sidebar: new "Canvases" section below "Notes"
- Create, rename, delete via context menu
- List shows: title, element count, last modified

## Rendering Approach

SwiftUI `Canvas` view (same pattern as GraphCanvasView) with overlay views for selection handles and text editing. Manual hit testing via coordinate math on element frames.

## Visual Style

- Flat solid colors, no gradients (matches existing theme)
- Floating toolbar: dark surface, border, rounded pill shape
- Status bar: same style as graph view status bar
- Tool icons: SF Symbols, mint accent for active tool

## Future (v2)

- Per-note embedded canvas (tab in editor view)
- Export as PNG/SVG
- Canvas elements linkable to notes (click shape → opens note)
- Collaborative editing prep
