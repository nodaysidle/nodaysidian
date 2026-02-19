import SwiftUI
import CoreData

// MARK: - WhiteboardTool

enum WhiteboardTool: String, CaseIterable {
    case select, rect, ellipse, arrow, text, pencil

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

    var label: String { rawValue.capitalized }
}

// MARK: - WhiteboardViewModel

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
        canvasOffset = .zero
        canvasScale = 1.0
    }

    func deleteCanvas(_ canvas: CanvasEntity) {
        guard let context else { return }
        context.delete(canvas)
        try? context.save()
        canvases.removeAll { $0.id == canvas.id }
        if selectedCanvas?.id == canvas.id {
            selectedCanvas = nil
            elements.removeAll()
            selectedElementId = nil
        }
    }

    func saveCurrentCanvas() {
        guard let canvas = selectedCanvas, let context else { return }
        canvas.elements = elements
        canvas.modifiedAt = Date()
        try? context.save()
    }

    // MARK: - Undo / Redo

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func pushUndo() {
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
        selectedElementId = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(elements)
        elements = next
        selectedElementId = nil
    }

    // MARK: - Element CRUD

    func addElement(_ element: CanvasElement) {
        pushUndo()
        elements.append(element)
        selectedElementId = element.id
    }

    func updateElement(_ element: CanvasElement) {
        guard let idx = elements.firstIndex(where: { $0.id == element.id }) else { return }
        pushUndo()
        elements[idx] = element
    }

    func deleteSelected() {
        guard let id = selectedElementId else { return }
        pushUndo()
        elements.removeAll { $0.id == id }
        selectedElementId = nil
    }

    func selectAll() {
        // Select the last element as the "active" selection
        // (multi-select could be added later with a Set<UUID>)
        selectedElementId = elements.last?.id
    }

    // MARK: - Hit Testing

    func hitTest(point: CGPoint) -> CanvasElement? {
        // Iterate reversed so topmost (last drawn) elements are tested first
        for element in elements.reversed() {
            if elementContains(element, point: point) {
                return element
            }
        }
        return nil
    }

    func elementContains(_ element: CanvasElement, point: CGPoint) -> Bool {
        switch element.type {
        case .rect, .text:
            let frame = element.frame.insetBy(dx: -4, dy: -4)
            return frame.contains(point)

        case .ellipse:
            // Ellipse equation: ((x-cx)/rx)^2 + ((y-cy)/ry)^2 <= 1
            let cx = element.x + element.width / 2
            let cy = element.y + element.height / 2
            let rx = max(abs(element.width) / 2, 1)
            let ry = max(abs(element.height) / 2, 1)
            let dx = (point.x - cx) / rx
            let dy = (point.y - cy) / ry
            return (dx * dx + dy * dy) <= 1.2  // slight tolerance

        case .line, .arrow:
            let start = CGPoint(x: element.x, y: element.y)
            let end = CGPoint(x: element.x + element.width, y: element.y + element.height)
            let dist = distanceToLine(point: point, from: start, to: end)
            return dist < max(element.strokeWidth + 4, 8)

        case .pencil:
            guard let points = element.points, points.count >= 2 else { return false }
            let threshold = max(element.strokeWidth + 4, 8)
            for i in 0..<(points.count - 1) {
                let a = points[i].cgPoint
                let b = points[i + 1].cgPoint
                if distanceToLine(point: point, from: a, to: b) < threshold {
                    return true
                }
            }
            return false
        }
    }

    func distanceToLine(point: CGPoint, from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSq = dx * dx + dy * dy

        if lengthSq < 0.001 {
            // Degenerate line — just distance to point a
            let px = point.x - a.x
            let py = point.y - a.y
            return sqrt(px * px + py * py)
        }

        // Project point onto line segment, clamped to [0,1]
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSq))
        let projX = a.x + t * dx
        let projY = a.y + t * dy
        let ex = point.x - projX
        let ey = point.y - projY
        return sqrt(ex * ex + ey * ey)
    }

    // MARK: - Drawing Completion

    func finishDrawingShape() {
        let minX = min(drawStart.x, drawCurrent.x)
        let minY = min(drawStart.y, drawCurrent.y)
        let w = abs(drawCurrent.x - drawStart.x)
        let h = abs(drawCurrent.y - drawStart.y)

        guard w > 2 || h > 2 else {
            isDrawing = false
            return
        }

        let elementType: CanvasElementType
        switch activeTool {
        case .rect:    elementType = .rect
        case .ellipse: elementType = .ellipse
        case .arrow:   elementType = .arrow
        default:       isDrawing = false; return
        }

        let element: CanvasElement
        if elementType == .arrow {
            // Arrows store start in (x,y) and delta in (width,height)
            element = CanvasElement(
                type: .arrow,
                x: drawStart.x,
                y: drawStart.y,
                width: drawCurrent.x - drawStart.x,
                height: drawCurrent.y - drawStart.y,
                strokeColor: strokeColor.toHex(),
                fillColor: nil,
                strokeWidth: strokeWidth,
                arrowHead: true
            )
        } else {
            element = CanvasElement(
                type: elementType,
                x: minX,
                y: minY,
                width: w,
                height: h,
                strokeColor: strokeColor.toHex(),
                fillColor: hasFill ? (fillColor ?? strokeColor).toHex() : nil,
                strokeWidth: strokeWidth
            )
        }

        addElement(element)
        isDrawing = false
    }

    func finishPencilStroke() {
        guard pencilPoints.count >= 2 else {
            pencilPoints.removeAll()
            isDrawing = false
            return
        }

        // Compute bounding box
        let xs = pencilPoints.map(\.x)
        let ys = pencilPoints.map(\.y)
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        let maxX = xs.max() ?? 0
        let maxY = ys.max() ?? 0

        let codablePoints = pencilPoints.map { CodablePoint($0) }

        let element = CanvasElement(
            type: .pencil,
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY,
            strokeColor: strokeColor.toHex(),
            strokeWidth: strokeWidth,
            points: codablePoints
        )

        addElement(element)
        pencilPoints.removeAll()
        isDrawing = false
    }

    // MARK: - Text

    func placeText(at point: CGPoint) {
        isEditingText = true
        editingElementId = nil
        editingText = ""
        textEditPosition = point
    }

    func commitText() {
        guard isEditingText else { return }
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editId = editingElementId {
            // Editing existing text element
            if trimmed.isEmpty {
                // Delete if empty
                selectedElementId = editId
                deleteSelected()
            } else if var existing = elements.first(where: { $0.id == editId }) {
                existing.text = trimmed
                updateElement(existing)
            }
        } else if !trimmed.isEmpty {
            // New text element
            let element = CanvasElement(
                type: .text,
                x: textEditPosition.x,
                y: textEditPosition.y,
                width: max(Double(trimmed.count) * 8, 60),
                height: 24,
                strokeColor: strokeColor.toHex(),
                text: trimmed
            )
            addElement(element)
        }

        isEditingText = false
        editingElementId = nil
        editingText = ""
    }

    func beginEditingText(_ element: CanvasElement) {
        guard element.type == .text else { return }
        isEditingText = true
        editingElementId = element.id
        editingText = element.text ?? ""
        textEditPosition = CGPoint(x: element.x, y: element.y)
    }

    // MARK: - Move

    func moveSelected(by delta: CGSize) {
        guard let id = selectedElementId,
              let idx = elements.firstIndex(where: { $0.id == id }) else { return }
        elements[idx].x += delta.width
        elements[idx].y += delta.height
    }

    func commitMove() {
        // Push undo after a drag completes (the drag itself mutates directly)
        // We push the pre-move state — but since moveSelected mutates in place,
        // we rely on the caller having called pushUndo() at drag start.
        // This method is a hook for save-on-drag-end.
        saveCurrentCanvas()
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
