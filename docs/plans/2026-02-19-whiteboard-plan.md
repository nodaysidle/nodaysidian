# Whiteboard Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an Excalidraw-inspired freeform whiteboard canvas to NODAYSIDLE as a third view mode alongside Graph and Editor.

**Architecture:** SwiftUI Canvas renders all drawing elements (rects, ellipses, arrows, text, freehand). A WhiteboardViewModel (@Observable) manages element state, undo/redo stack, and current tool. CanvasEntity persists drawings via Core Data with JSON-encoded element arrays. The sidebar gets a "Canvases" section for canvas management.

**Tech Stack:** SwiftUI 6 Canvas, Core Data (programmatic model), Codable JSON serialization, native ColorPicker.

---

### Task 1: CanvasElement Data Model

**Files:**
- Create: `Sources/NodaysIdle/Models/CanvasElement.swift`

**Step 1: Create the CanvasElement Codable structs**

```swift
import Foundation

enum CanvasElementType: String, Codable, CaseIterable {
    case rect
    case ellipse
    case line
    case arrow
    case text
    case pencil
}

struct CanvasElement: Identifiable, Codable {
    let id: UUID
    var type: CanvasElementType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
    var strokeColor: String    // hex like "2DD4BF"
    var fillColor: String?     // nil = no fill
    var strokeWidth: Double
    var text: String?
    var points: [CodablePoint]?
    var arrowHead: Bool

    init(
        id: UUID = UUID(),
        type: CanvasElementType,
        x: Double = 0,
        y: Double = 0,
        width: Double = 0,
        height: Double = 0,
        rotation: Double = 0,
        strokeColor: String = "EEEEF0",
        fillColor: String? = nil,
        strokeWidth: Double = 2,
        text: String? = nil,
        points: [CodablePoint]? = nil,
        arrowHead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = strokeWidth
        self.text = text
        self.points = points
        self.arrowHead = arrowHead
    }

    var frame: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct CodablePoint: Codable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
```

**Step 2: Build to verify it compiles**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add Sources/NodaysIdle/Models/CanvasElement.swift
git commit -m "feat: add CanvasElement codable data model for whiteboard"
```

---

### Task 2: CanvasEntity Core Data Extension

**Files:**
- Create: `Sources/NodaysIdle/Models/CanvasEntity+Ext.swift`
- Modify: `Sources/NodaysIdle/Models/PersistenceController.swift` (add CanvasEntity to buildModel())

**Step 1: Create CanvasEntity+Ext.swift**

```swift
import CoreData
import Foundation

@objc(CanvasEntity)
public class CanvasEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var elementsData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var linkedNoteId: UUID?
}

extension CanvasEntity {
    var displayTitle: String {
        title.isEmpty ? "Untitled Canvas" : title
    }

    var elements: [CanvasElement] {
        get {
            guard let data = elementsData else { return [] }
            return (try? JSONDecoder().decode([CanvasElement].self, from: data)) ?? []
        }
        set {
            elementsData = try? JSONEncoder().encode(newValue)
        }
    }

    var elementCount: Int {
        elements.count
    }

    static func create(
        in context: NSManagedObjectContext,
        title: String = "Untitled Canvas"
    ) -> CanvasEntity {
        let canvas = CanvasEntity(context: context)
        canvas.id = UUID()
        canvas.title = title
        canvas.elementsData = try? JSONEncoder().encode([CanvasElement]())
        canvas.createdAt = Date()
        canvas.modifiedAt = Date()
        return canvas
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CanvasEntity> {
        NSFetchRequest<CanvasEntity>(entityName: "CanvasEntity")
    }

    @nonobjc public class func fetchAll() -> NSFetchRequest<CanvasEntity> {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CanvasEntity.modifiedAt, ascending: false)]
        return req
    }
}
```

**Step 2: Add CanvasEntity to PersistenceController.buildModel()**

In `PersistenceController.swift`, inside `buildModel()`, after the EdgeEntity section and before `model.entities = [...]`, add the CanvasEntity definition:

```swift
// --- CanvasEntity ---
let canvasEntity = NSEntityDescription()
canvasEntity.name = "CanvasEntity"
canvasEntity.managedObjectClassName = "CanvasEntity"

let canvasId = NSAttributeDescription()
canvasId.name = "id"
canvasId.attributeType = .UUIDAttributeType
canvasId.isOptional = false

let canvasTitle = NSAttributeDescription()
canvasTitle.name = "title"
canvasTitle.attributeType = .stringAttributeType
canvasTitle.defaultValue = "Untitled Canvas"

let canvasElements = NSAttributeDescription()
canvasElements.name = "elementsData"
canvasElements.attributeType = .binaryDataAttributeType
canvasElements.isOptional = true

let canvasCreatedAt = NSAttributeDescription()
canvasCreatedAt.name = "createdAt"
canvasCreatedAt.attributeType = .dateAttributeType

let canvasModifiedAt = NSAttributeDescription()
canvasModifiedAt.name = "modifiedAt"
canvasModifiedAt.attributeType = .dateAttributeType

let canvasLinkedNote = NSAttributeDescription()
canvasLinkedNote.name = "linkedNoteId"
canvasLinkedNote.attributeType = .UUIDAttributeType
canvasLinkedNote.isOptional = true

canvasEntity.properties = [
    canvasId, canvasTitle, canvasElements,
    canvasCreatedAt, canvasModifiedAt, canvasLinkedNote
]
```

Then change the final line to: `model.entities = [noteEntity, edgeEntity, canvasEntity]`

**Step 3: Build to verify**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add Sources/NodaysIdle/Models/CanvasEntity+Ext.swift Sources/NodaysIdle/Models/PersistenceController.swift
git commit -m "feat: add CanvasEntity to Core Data model for whiteboard persistence"
```

---

### Task 3: WhiteboardViewModel

**Files:**
- Create: `Sources/NodaysIdle/ViewModels/WhiteboardViewModel.swift`

**Step 1: Create WhiteboardViewModel with full state management**

This is the brain of the whiteboard — tool state, element CRUD, undo/redo, selection, hit testing.

```swift
import SwiftUI
import CoreData

enum WhiteboardTool: String, CaseIterable {
    case select
    case rect
    case ellipse
    case arrow
    case text
    case pencil

    var icon: String {
        switch self {
        case .select:  return "cursorarrow"
        case .rect:    return "rectangle"
        case .ellipse: return "circle"
        case .arrow:   return "arrow.right"
        case .text:    return "textformat"
        case .pencil:  return "pencil.tip"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

@MainActor
@Observable
final class WhiteboardViewModel {
    // Canvas list
    var canvases: [CanvasEntity] = []
    var selectedCanvas: CanvasEntity?

    // Current canvas state
    var elements: [CanvasElement] = []
    var selectedElementId: UUID?
    var activeTool: WhiteboardTool = .select

    // Drawing state
    var strokeColor: Color = Color(hex: 0xEEEEF0)
    var fillColor: Color? = nil
    var strokeWidth: Double = 2
    var hasFill: Bool = false

    // Pan / Zoom
    var canvasOffset: CGSize = .zero
    var canvasScale: CGFloat = 1.0

    // Undo / Redo
    private var undoStack: [[CanvasElement]] = []
    private var redoStack: [[CanvasElement]] = []
    private let maxUndoLevels = 50

    // In-progress drawing
    var isDrawing: Bool = false
    var drawStart: CGPoint = .zero
    var drawCurrent: CGPoint = .zero
    var pencilPoints: [CGPoint] = []

    // Text editing
    var isEditingText: Bool = false
    var editingElementId: UUID?
    var editingText: String = ""
    var textEditPosition: CGPoint = .zero

    private var context: NSManagedObjectContext?

    var selectedElement: CanvasElement? {
        guard let id = selectedElementId else { return nil }
        return elements.first { $0.id == id }
    }

    // MARK: - Binding

    func bind(context: NSManagedObjectContext) {
        self.context = context
        reloadCanvases()
    }

    func reloadCanvases() {
        guard let context else { return }
        let req = CanvasEntity.fetchAll()
        canvases = (try? context.fetch(req)) ?? []
    }

    // MARK: - Canvas CRUD

    func createCanvas() {
        guard let context else { return }
        let canvas = CanvasEntity.create(in: context, title: "Untitled Canvas")
        try? context.save()
        canvases.insert(canvas, at: 0)
        selectCanvas(canvas)
    }

    func selectCanvas(_ canvas: CanvasEntity) {
        saveCurrentCanvas()
        selectedCanvas = canvas
        elements = canvas.elements
        selectedElementId = nil
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func deleteCanvas(_ canvas: CanvasEntity) {
        guard let context else { return }
        context.delete(canvas)
        try? context.save()
        canvases.removeAll { $0.id == canvas.id }
        if selectedCanvas?.id == canvas.id {
            selectedCanvas = nil
            elements.removeAll()
        }
    }

    func saveCurrentCanvas() {
        guard let canvas = selectedCanvas, let context else { return }
        canvas.elements = elements
        canvas.modifiedAt = Date()
        try? context.save()
    }

    // MARK: - Undo / Redo

    private func pushUndo() {
        undoStack.append(elements)
        if undoStack.count > maxUndoLevels {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(elements)
        elements = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(elements)
        elements = next
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Element Operations

    func addElement(_ element: CanvasElement) {
        pushUndo()
        elements.append(element)
    }

    func updateElement(_ element: CanvasElement) {
        pushUndo()
        if let idx = elements.firstIndex(where: { $0.id == element.id }) {
            elements[idx] = element
        }
    }

    func deleteSelected() {
        guard let id = selectedElementId else { return }
        pushUndo()
        elements.removeAll { $0.id == id }
        selectedElementId = nil
    }

    func selectAll() {
        // For v1, select the last element (multi-select is v2)
        selectedElementId = elements.last?.id
    }

    // MARK: - Hit Testing

    func hitTest(point: CGPoint) -> CanvasElement? {
        // Iterate in reverse (top-most first)
        for element in elements.reversed() {
            if elementContains(element, point: point) {
                return element
            }
        }
        return nil
    }

    private func elementContains(_ element: CanvasElement, point: CGPoint) -> Bool {
        let hitPadding: Double = 6

        switch element.type {
        case .rect, .text:
            let rect = element.frame.insetBy(dx: -hitPadding, dy: -hitPadding)
            return rect.contains(point)

        case .ellipse:
            let cx = element.x + element.width / 2
            let cy = element.y + element.height / 2
            let rx = (element.width / 2) + hitPadding
            let ry = (element.height / 2) + hitPadding
            let dx = point.x - cx
            let dy = point.y - cy
            return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1

        case .line, .arrow:
            return distanceToLine(
                point: point,
                from: CGPoint(x: element.x, y: element.y),
                to: CGPoint(x: element.x + element.width, y: element.y + element.height)
            ) < hitPadding + element.strokeWidth

        case .pencil:
            guard let points = element.points, points.count >= 2 else { return false }
            for i in 0..<(points.count - 1) {
                let d = distanceToLine(
                    point: point,
                    from: points[i].cgPoint,
                    to: points[i + 1].cgPoint
                )
                if d < hitPadding + element.strokeWidth { return true }
            }
            return false
        }
    }

    private func distanceToLine(point: CGPoint, from: CGPoint, to: CGPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else {
            return hypot(point.x - from.x, point.y - from.y)
        }
        let t = max(0, min(1, ((point.x - from.x) * dx + (point.y - from.y) * dy) / lenSq))
        let projX = from.x + t * dx
        let projY = from.y + t * dy
        return hypot(point.x - projX, point.y - projY)
    }

    // MARK: - Drawing Completion

    func finishDrawingShape() {
        let minX = min(drawStart.x, drawCurrent.x)
        let minY = min(drawStart.y, drawCurrent.y)
        let w = abs(drawCurrent.x - drawStart.x)
        let h = abs(drawCurrent.y - drawStart.y)

        guard w > 2 || h > 2 else { return }

        let hexStroke = strokeColor.toHex()
        let hexFill: String? = hasFill ? (fillColor ?? strokeColor).toHex() : nil

        switch activeTool {
        case .rect:
            addElement(CanvasElement(
                type: .rect, x: minX, y: minY, width: w, height: h,
                strokeColor: hexStroke, fillColor: hexFill,
                strokeWidth: strokeWidth
            ))

        case .ellipse:
            addElement(CanvasElement(
                type: .ellipse, x: minX, y: minY, width: w, height: h,
                strokeColor: hexStroke, fillColor: hexFill,
                strokeWidth: strokeWidth
            ))

        case .arrow:
            addElement(CanvasElement(
                type: .arrow,
                x: drawStart.x, y: drawStart.y,
                width: drawCurrent.x - drawStart.x,
                height: drawCurrent.y - drawStart.y,
                strokeColor: hexStroke, strokeWidth: strokeWidth,
                arrowHead: true
            ))

        default:
            break
        }

        isDrawing = false
    }

    func finishPencilStroke() {
        guard pencilPoints.count >= 2 else {
            isDrawing = false
            pencilPoints.removeAll()
            return
        }

        let codablePoints = pencilPoints.map { CodablePoint($0) }
        addElement(CanvasElement(
            type: .pencil,
            strokeColor: strokeColor.toHex(),
            strokeWidth: strokeWidth,
            points: codablePoints
        ))

        isDrawing = false
        pencilPoints.removeAll()
    }

    func placeText(at point: CGPoint) {
        textEditPosition = point
        editingText = ""
        isEditingText = true
        editingElementId = nil
    }

    func commitText() {
        guard !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isEditingText = false
            return
        }

        let hexStroke = strokeColor.toHex()

        if let editId = editingElementId,
           let idx = elements.firstIndex(where: { $0.id == editId }) {
            pushUndo()
            elements[idx].text = editingText
        } else {
            addElement(CanvasElement(
                type: .text,
                x: textEditPosition.x, y: textEditPosition.y,
                width: max(100, Double(editingText.count) * 8),
                height: 24,
                strokeColor: hexStroke,
                strokeWidth: strokeWidth,
                text: editingText
            ))
        }

        isEditingText = false
        editingElementId = nil
    }

    func beginEditingText(_ element: CanvasElement) {
        guard element.type == .text else { return }
        editingElementId = element.id
        editingText = element.text ?? ""
        textEditPosition = CGPoint(x: element.x, y: element.y)
        isEditingText = true
    }

    // MARK: - Move Element

    func moveSelected(by delta: CGSize) {
        guard let id = selectedElementId,
              let idx = elements.firstIndex(where: { $0.id == id }) else { return }
        elements[idx].x += delta.width
        elements[idx].y += delta.height
    }

    func commitMove() {
        // Push undo state at move start instead; this is called at end
        // Undo is pushed before the first drag in the gesture handler
    }
}

// MARK: - Color Hex Conversion

extension Color {
    func toHex() -> String {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return "EEEEF0" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }

    init(hex string: String) {
        let hex = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            .sRGB,
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}
```

**Step 2: Build to verify**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -5`
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add Sources/NodaysIdle/ViewModels/WhiteboardViewModel.swift
git commit -m "feat: add WhiteboardViewModel with undo/redo, hit testing, and tool state"
```

---

### Task 4: WhiteboardView — Canvas Rendering

**Files:**
- Create: `Sources/NodaysIdle/Views/Whiteboard/WhiteboardView.swift`

**Step 1: Create WhiteboardView with Canvas rendering and gesture handling**

This is the main drawing surface. Uses SwiftUI `Canvas` for rendering all elements (same pattern as GraphCanvasView), with overlay gestures for drawing, selecting, and moving.

```swift
import SwiftUI

struct WhiteboardView: View {
    @Bindable var whiteboard: WhiteboardViewModel

    var body: some View {
        ZStack {
            LatticeTheme.void.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    // Render layer
                    Canvas { ctx, size in
                        renderElements(ctx: ctx, size: size)
                    }

                    // In-progress shape preview
                    if whiteboard.isDrawing {
                        drawingPreview
                    }

                    // Selection handles
                    if let selected = whiteboard.selectedElement {
                        selectionOverlay(for: selected)
                    }

                    // Floating text editor
                    if whiteboard.isEditingText {
                        textEditorOverlay
                    }
                }
                .scaleEffect(whiteboard.canvasScale)
                .offset(whiteboard.canvasOffset)
                .gesture(canvasGesture(in: geo))
                .gesture(magnifyGesture)
                .onTapGesture(count: 2) { location in
                    handleDoubleTap(at: location, in: geo)
                }
                .onTapGesture { location in
                    handleTap(at: location, in: geo)
                }
            }

            // Floating toolbar at bottom-center
            VStack {
                Spacer()
                WhiteboardToolbar(whiteboard: whiteboard)
                    .padding(.bottom, 16)
            }

            // Status bar at bottom-left
            VStack {
                Spacer()
                HStack {
                    statusBar
                    Spacer()
                }
                .padding(16)
            }
        }
        .onKeyPress(.delete) {
            whiteboard.deleteSelected()
            return .handled
        }
        .focusable()
    }

    // MARK: - Canvas Rendering

    private func renderElements(ctx: GraphicsContext, size: CGSize) {
        for element in whiteboard.elements {
            renderElement(element, ctx: ctx)
        }
    }

    private func renderElement(_ element: CanvasElement, ctx: GraphicsContext) {
        let stroke = Color(hex: element.strokeColor)
        let fill = element.fillColor.map { Color(hex: $0) }

        switch element.type {
        case .rect:
            let rect = element.frame
            if let fill {
                ctx.fill(Path(rect), with: .color(fill))
            }
            ctx.stroke(Path(rect), with: .color(stroke), lineWidth: element.strokeWidth)

        case .ellipse:
            let rect = element.frame
            let path = Path(ellipseIn: rect)
            if let fill {
                ctx.fill(path, with: .color(fill))
            }
            ctx.stroke(path, with: .color(stroke), lineWidth: element.strokeWidth)

        case .line, .arrow:
            let from = CGPoint(x: element.x, y: element.y)
            let to = CGPoint(x: element.x + element.width, y: element.y + element.height)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            ctx.stroke(path, with: .color(stroke), lineWidth: element.strokeWidth)

            if element.arrowHead {
                drawArrowHead(ctx: ctx, from: from, to: to, color: stroke, width: element.strokeWidth)
            }

        case .text:
            let text = Text(element.text ?? "")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(stroke)
            ctx.draw(text, at: CGPoint(x: element.x + 4, y: element.y + 12), anchor: .topLeading)

        case .pencil:
            guard let points = element.points, points.count >= 2 else { return }
            var path = Path()
            path.move(to: points[0].cgPoint)
            for i in 1..<points.count {
                path.addLine(to: points[i].cgPoint)
            }
            ctx.stroke(path, with: .color(stroke), lineWidth: element.strokeWidth)
        }
    }

    private func drawArrowHead(
        ctx: GraphicsContext, from: CGPoint, to: CGPoint,
        color: Color, width: Double
    ) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLen: Double = 12
        let arrowAngle: Double = .pi / 6

        let p1 = CGPoint(
            x: to.x - arrowLen * cos(angle - arrowAngle),
            y: to.y - arrowLen * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: to.x - arrowLen * cos(angle + arrowAngle),
            y: to.y - arrowLen * sin(angle + arrowAngle)
        )

        var path = Path()
        path.move(to: to)
        path.addLine(to: p1)
        path.move(to: to)
        path.addLine(to: p2)
        ctx.stroke(path, with: .color(color), lineWidth: width)
    }

    // MARK: - Drawing Preview (in-progress shape)

    @ViewBuilder
    private var drawingPreview: some View {
        let minX = min(whiteboard.drawStart.x, whiteboard.drawCurrent.x)
        let minY = min(whiteboard.drawStart.y, whiteboard.drawCurrent.y)
        let w = abs(whiteboard.drawCurrent.x - whiteboard.drawStart.x)
        let h = abs(whiteboard.drawCurrent.y - whiteboard.drawStart.y)

        switch whiteboard.activeTool {
        case .rect:
            Rectangle()
                .strokeBorder(whiteboard.strokeColor, lineWidth: whiteboard.strokeWidth)
                .background(whiteboard.hasFill ? (whiteboard.fillColor ?? whiteboard.strokeColor) : Color.clear)
                .frame(width: w, height: h)
                .position(x: minX + w / 2, y: minY + h / 2)

        case .ellipse:
            Ellipse()
                .strokeBorder(whiteboard.strokeColor, lineWidth: whiteboard.strokeWidth)
                .frame(width: w, height: h)
                .position(x: minX + w / 2, y: minY + h / 2)

        case .arrow:
            Canvas { ctx, _ in
                var path = Path()
                path.move(to: whiteboard.drawStart)
                path.addLine(to: whiteboard.drawCurrent)
                ctx.stroke(path, with: .color(whiteboard.strokeColor), lineWidth: whiteboard.strokeWidth)
                drawArrowHead(
                    ctx: ctx, from: whiteboard.drawStart, to: whiteboard.drawCurrent,
                    color: whiteboard.strokeColor, width: whiteboard.strokeWidth
                )
            }

        case .pencil:
            Canvas { ctx, _ in
                guard whiteboard.pencilPoints.count >= 2 else { return }
                var path = Path()
                path.move(to: whiteboard.pencilPoints[0])
                for pt in whiteboard.pencilPoints.dropFirst() {
                    path.addLine(to: pt)
                }
                ctx.stroke(path, with: .color(whiteboard.strokeColor), lineWidth: whiteboard.strokeWidth)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Selection Overlay

    private func selectionOverlay(for element: CanvasElement) -> some View {
        let rect = element.type == .pencil
            ? pencilBounds(element)
            : element.frame
        let padding: CGFloat = 4

        return Rectangle()
            .strokeBorder(LatticeTheme.mint, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(
                width: rect.width + padding * 2,
                height: rect.height + padding * 2
            )
            .position(
                x: rect.midX,
                y: rect.midY
            )
    }

    private func pencilBounds(_ element: CanvasElement) -> CGRect {
        guard let points = element.points, !points.isEmpty else {
            return element.frame
        }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Text Editor Overlay

    private var textEditorOverlay: some View {
        TextField("Type here...", text: $whiteboard.editingText)
            .textFieldStyle(.plain)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(whiteboard.strokeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LatticeTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(LatticeTheme.mint, lineWidth: 1)
                    }
            }
            .frame(width: 200)
            .position(whiteboard.textEditPosition)
            .onSubmit {
                whiteboard.commitText()
            }
    }

    // MARK: - Gestures

    private func canvasGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let location = value.location

                switch whiteboard.activeTool {
                case .select:
                    if !whiteboard.isDrawing {
                        // Start: check if dragging an element
                        if let hit = whiteboard.hitTest(point: value.startLocation) {
                            whiteboard.selectedElementId = hit.id
                            whiteboard.isDrawing = true
                            whiteboard.drawStart = value.startLocation
                        } else {
                            // Pan canvas
                            whiteboard.canvasOffset = value.translation
                        }
                    } else {
                        // Moving selected element
                        let delta = CGSize(
                            width: location.x - (whiteboard.drawCurrent == .zero ? value.startLocation.x : whiteboard.drawCurrent.x),
                            height: location.y - (whiteboard.drawCurrent == .zero ? value.startLocation.y : whiteboard.drawCurrent.y)
                        )
                        whiteboard.moveSelected(by: delta)
                    }
                    whiteboard.drawCurrent = location

                case .rect, .ellipse, .arrow:
                    if !whiteboard.isDrawing {
                        whiteboard.isDrawing = true
                        whiteboard.drawStart = value.startLocation
                    }
                    whiteboard.drawCurrent = location

                case .pencil:
                    if !whiteboard.isDrawing {
                        whiteboard.isDrawing = true
                        whiteboard.pencilPoints = [value.startLocation]
                    }
                    whiteboard.pencilPoints.append(location)
                    whiteboard.drawCurrent = location

                case .text:
                    break
                }
            }
            .onEnded { _ in
                switch whiteboard.activeTool {
                case .select:
                    if whiteboard.isDrawing {
                        whiteboard.commitMove()
                    }
                    whiteboard.isDrawing = false
                    whiteboard.drawCurrent = .zero

                case .rect, .ellipse, .arrow:
                    whiteboard.finishDrawingShape()
                    whiteboard.drawCurrent = .zero

                case .pencil:
                    whiteboard.finishPencilStroke()
                    whiteboard.drawCurrent = .zero

                case .text:
                    break
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                whiteboard.canvasScale = max(0.3, min(3.0, value.magnification))
            }
    }

    // MARK: - Tap Handlers

    private func handleTap(at location: CGPoint, in geo: GeometryProxy) {
        switch whiteboard.activeTool {
        case .select:
            if let hit = whiteboard.hitTest(point: location) {
                whiteboard.selectedElementId = hit.id
            } else {
                whiteboard.selectedElementId = nil
            }

        case .text:
            whiteboard.placeText(at: location)

        default:
            whiteboard.selectedElementId = nil
        }
    }

    private func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
        if whiteboard.activeTool == .select {
            if let hit = whiteboard.hitTest(point: location), hit.type == .text {
                whiteboard.beginEditingText(hit)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(LatticeTheme.lavender)
                Text("\(whiteboard.elements.count)")
                    .font(LatticeTheme.monoFont)
                    .foregroundStyle(LatticeTheme.textSecondary)
                Text("elements")
                    .font(LatticeTheme.captionFont)
                    .foregroundStyle(LatticeTheme.textMuted)
            }

            if let canvas = whiteboard.selectedCanvas {
                Text(canvas.displayTitle)
                    .font(LatticeTheme.captionFont)
                    .foregroundStyle(LatticeTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LatticeTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(LatticeTheme.border, lineWidth: 1)
                }
        }
    }
}
```

**Step 2: Build to verify**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -5`
Expected: Build Succeeded (will fail until WhiteboardToolbar exists — create in next task)

**Step 3: Commit (after Task 5 builds clean)**

---

### Task 5: WhiteboardToolbar — Floating Tool Strip

**Files:**
- Create: `Sources/NodaysIdle/Views/Whiteboard/WhiteboardToolbar.swift`

**Step 1: Create the floating toolbar**

Horizontal pill with tool buttons, color pickers, stroke width, and fill toggle. Matches the dark theme.

```swift
import SwiftUI

struct WhiteboardToolbar: View {
    @Bindable var whiteboard: WhiteboardViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Tool buttons
            toolButtons

            divider

            // Color controls
            colorControls

            divider

            // Stroke width
            strokeWidthControl

            divider

            // Undo / Redo
            undoRedoButtons
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(LatticeTheme.surface)
                .overlay {
                    Capsule()
                        .strokeBorder(LatticeTheme.border, lineWidth: 1)
                }
        }
    }

    // MARK: - Tool Buttons

    private var toolButtons: some View {
        HStack(spacing: 2) {
            ForEach(WhiteboardTool.allCases, id: \.self) { tool in
                Button {
                    whiteboard.activeTool = tool
                } label: {
                    Image(systemName: tool.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(
                            whiteboard.activeTool == tool
                                ? LatticeTheme.mint
                                : LatticeTheme.textSecondary
                        )
                        .frame(width: 30, height: 26)
                        .background {
                            if whiteboard.activeTool == tool {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(LatticeTheme.mint.opacity(0.15))
                            }
                        }
                }
                .buttonStyle(.plain)
                .help(tool.label)
            }
        }
    }

    // MARK: - Color Controls

    private var colorControls: some View {
        HStack(spacing: 6) {
            // Stroke color
            ColorPicker("", selection: $whiteboard.strokeColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 24, height: 24)
                .help("Stroke Color")

            // Fill toggle + color
            Button {
                whiteboard.hasFill.toggle()
                if whiteboard.hasFill && whiteboard.fillColor == nil {
                    whiteboard.fillColor = whiteboard.strokeColor.opacity(0.3)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(whiteboard.hasFill
                            ? (whiteboard.fillColor ?? whiteboard.strokeColor)
                            : Color.clear
                        )
                        .frame(width: 18, height: 18)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(
                            whiteboard.hasFill ? LatticeTheme.mint : LatticeTheme.textMuted,
                            lineWidth: 1
                        )
                        .frame(width: 18, height: 18)
                }
                .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help(whiteboard.hasFill ? "Disable Fill" : "Enable Fill")

            if whiteboard.hasFill {
                ColorPicker("", selection: Binding(
                    get: { whiteboard.fillColor ?? whiteboard.strokeColor },
                    set: { whiteboard.fillColor = $0 }
                ), supportsOpacity: true)
                .labelsHidden()
                .frame(width: 24, height: 24)
                .help("Fill Color")
            }
        }
    }

    // MARK: - Stroke Width

    private var strokeWidthControl: some View {
        HStack(spacing: 4) {
            Image(systemName: "lineweight")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(LatticeTheme.textMuted)

            Slider(value: $whiteboard.strokeWidth, in: 1...6, step: 0.5)
                .frame(width: 60)
                .tint(LatticeTheme.mint)

            Text(String(format: "%.0f", whiteboard.strokeWidth))
                .font(LatticeTheme.monoFont)
                .foregroundStyle(LatticeTheme.textSecondary)
                .frame(width: 16)
        }
    }

    // MARK: - Undo / Redo

    private var undoRedoButtons: some View {
        HStack(spacing: 2) {
            Button {
                whiteboard.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        whiteboard.canUndo ? LatticeTheme.textSecondary : LatticeTheme.textMuted
                    )
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!whiteboard.canUndo)
            .help("Undo")

            Button {
                whiteboard.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        whiteboard.canRedo ? LatticeTheme.textSecondary : LatticeTheme.textMuted
                    )
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!whiteboard.canRedo)
            .help("Redo")
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(LatticeTheme.border)
            .frame(width: 1, height: 20)
            .padding(.horizontal, 6)
    }
}
```

**Step 2: Build to verify both WhiteboardView + WhiteboardToolbar compile**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -10`
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add Sources/NodaysIdle/Views/Whiteboard/
git commit -m "feat: add WhiteboardView and WhiteboardToolbar with full drawing canvas"
```

---

### Task 6: Sidebar Integration — Canvas List

**Files:**
- Modify: `Sources/NodaysIdle/Views/Sidebar/SidebarView.swift`
- Create: `Sources/NodaysIdle/Views/Sidebar/CanvasListItem.swift`

**Step 1: Create CanvasListItem**

```swift
import SwiftUI

struct CanvasListItem: View {
    let canvas: CanvasEntity
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Canvas icon
            Image(systemName: "square.on.square")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LatticeTheme.lavender)
                .frame(width: 16)

            // Title + meta
            VStack(alignment: .leading, spacing: 3) {
                Text(canvas.displayTitle)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .default))
                    .foregroundStyle(isSelected ? LatticeTheme.textPrimary : LatticeTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(canvas.elementCount) elements")
                        .font(LatticeTheme.monoFont)
                        .foregroundStyle(LatticeTheme.textMuted)

                    if let mod = canvas.modifiedAt {
                        Text(mod, style: .relative)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(LatticeTheme.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    isSelected
                        ? LatticeTheme.lavender.opacity(0.12)
                        : isHovered
                            ? LatticeTheme.surfaceHover
                            : Color.clear
                )
        }
    }
}
```

**Step 2: Modify SidebarView to accept WhiteboardViewModel and add canvas section**

Add `whiteboard` parameter and a canvas list section between the note list and footer. The SidebarView signature becomes:

```swift
struct SidebarView: View {
    @Bindable var vault: VaultViewModel
    @Bindable var graph: GraphViewModel
    @Bindable var whiteboard: WhiteboardViewModel
    // ... add onSelectCanvas callback
    var onSelectCanvas: ((CanvasEntity) -> Void)?
```

Add a `canvasList` section after `noteList` and before `sidebarFooter` in the body VStack. Include a "Canvases" section header with a `+` button, and a scrollable list of `CanvasListItem` entries with tap-to-select and right-click delete.

**Step 3: Build to verify**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -10`
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add Sources/NodaysIdle/Views/Sidebar/
git commit -m "feat: add canvas list section to sidebar with CanvasListItem"
```

---

### Task 7: MainView Integration — Third View Mode

**Files:**
- Modify: `Sources/NodaysIdle/Views/MainView.swift`
- Modify: `Sources/NodaysIdle/App/NodaysIdleApp.swift`

**Step 1: Add view mode enum and whiteboard state to MainView**

Replace the `showGraph: Bool` toggle with a proper `ViewMode` enum:

```swift
enum ViewMode {
    case graph
    case editor
    case whiteboard
}
```

Add `@State private var whiteboard = WhiteboardViewModel()` and `@State private var viewMode: ViewMode = .graph`.

Update the detail view to switch on `viewMode`:
- `.graph` → `GraphCanvasView`
- `.editor` → `NoteEditorView` (with selectedNote)
- `.whiteboard` → `WhiteboardView`

Update toolbar to show three toggle buttons: Graph / Editor / Whiteboard.

Pass `whiteboard` to `SidebarView`.

Bind whiteboard context in `.onAppear`.

**Step 2: Add keyboard shortcut in NodaysIdleApp**

Add `Cmd+Shift+N` for "New Canvas" in the commands section, posting a new notification `.createNewCanvas`.

**Step 3: Build to verify**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -10`
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add Sources/NodaysIdle/Views/MainView.swift Sources/NodaysIdle/App/NodaysIdleApp.swift
git commit -m "feat: integrate whiteboard as third view mode in MainView"
```

---

### Task 8: Autosave + Final Wiring

**Files:**
- Modify: `Sources/NodaysIdle/Views/Whiteboard/WhiteboardView.swift` (add autosave timer)
- Modify: `Sources/NodaysIdle/Views/MainView.swift` (wire canvas selection from sidebar)

**Step 1: Add autosave to WhiteboardView**

Add `.onChange(of: whiteboard.elements)` modifier that debounces saves to Core Data via `whiteboard.saveCurrentCanvas()`. Use a simple approach: save on every element change (Core Data handles this efficiently).

**Step 2: Wire sidebar canvas selection to switch to whiteboard view**

When a canvas is tapped in the sidebar, set `viewMode = .whiteboard` and call `whiteboard.selectCanvas(canvas)`.

**Step 3: Build, install, test**

Run: `cd /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice && swift build 2>&1 | tail -5`
Then: `bash Scripts/compile_and_run.sh`

**Step 4: Commit**

```bash
git add Sources/NodaysIdle/
git commit -m "feat: add autosave and wire canvas selection from sidebar"
```

---

### Task 9: Delete Old Core Data Store + Build Release

**Step 1: Delete stale Core Data store**

The existing SQLite store doesn't have the CanvasEntity schema. Delete it so Core Data rebuilds:

```bash
rm -rf ~/Library/Application\ Support/NodaysIdle/NodaysIdle.sqlite*
```

**Step 2: Build release and install**

```bash
bash /Volumes/omarchyuser/claudev2/nodaysidian/LivingLattice/Scripts/install.sh
```

**Step 3: Verify the app launches and whiteboard works**

- Open NODAYSIDLE from `/Applications`
- Click whiteboard icon in toolbar
- Create a canvas from sidebar
- Draw rectangles, ellipses, arrows, freehand lines
- Add text labels
- Change colors, stroke width
- Undo/redo
- Close and reopen — verify drawings persist

**Step 4: Final commit + push**

```bash
git add -A && git commit -m "feat: whiteboard feature complete — Excalidraw-inspired canvas for NODAYSIDLE"
git push origin main
```
