import SwiftUI

struct WhiteboardView: View {
    @Bindable var whiteboard: WhiteboardViewModel

    // Drag state for moving elements
    @State private var isDraggingElement = false
    @State private var dragStartOffset: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

    var body: some View {
        ZStack {
            LatticeTheme.void
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    // Main canvas rendering
                    Canvas { ctx, size in
                        renderElements(ctx: ctx, size: size)
                    }

                    // Drawing preview overlay (in-progress shape)
                    if whiteboard.isDrawing {
                        drawingPreview
                    }

                    // Selection overlay
                    if let selected = whiteboard.selectedElement, !whiteboard.isDrawing {
                        selectionOverlay(for: selected)
                    }

                    // Text editor overlay
                    if whiteboard.isEditingText {
                        textEditorOverlay
                    }
                }
                .scaleEffect(whiteboard.canvasScale)
                .offset(whiteboard.canvasOffset)
                .gesture(canvasDragGesture(in: geo))
                .gesture(magnifyGesture)
                .onTapGesture(count: 2) { location in
                    handleDoubleTap(at: location, in: geo)
                }
                .onTapGesture(count: 1) { location in
                    handleSingleTap(at: location, in: geo)
                }
            }

            // Floating toolbar at bottom-center
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    WhiteboardToolbar(whiteboard: whiteboard)
                    Spacer()
                }
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
        .focusable()
        .onKeyPress(.delete) {
            whiteboard.deleteSelected()
            return .handled
        }
        .onChange(of: whiteboard.elements.count) {
            whiteboard.saveCurrentCanvas()
        }
        .onDisappear {
            whiteboard.saveCurrentCanvas()
        }
    }

    // MARK: - Canvas Rendering

    private func renderElements(ctx: GraphicsContext, size: CGSize) {
        for element in whiteboard.elements {
            renderElement(element, ctx: ctx)
        }
    }

    private func renderElement(_ element: CanvasElement, ctx: GraphicsContext) {
        let strokeColor = Color(hex: element.strokeColor)
        let lineWidth = CGFloat(element.strokeWidth)

        switch element.type {
        case .rect:
            let rect = element.frame
            if let fillHex = element.fillColor {
                let fill = Color(hex: fillHex)
                ctx.fill(Path(rect), with: .color(fill))
            }
            ctx.stroke(Path(rect), with: .color(strokeColor), lineWidth: lineWidth)

        case .ellipse:
            let rect = element.frame
            let path = Path(ellipseIn: rect)
            if let fillHex = element.fillColor {
                let fill = Color(hex: fillHex)
                ctx.fill(path, with: .color(fill))
            }
            ctx.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)

        case .line:
            let from = CGPoint(x: element.x, y: element.y)
            let to = CGPoint(x: element.x + element.width, y: element.y + element.height)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            ctx.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)

        case .arrow:
            let from = CGPoint(x: element.x, y: element.y)
            let to = CGPoint(x: element.x + element.width, y: element.y + element.height)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            ctx.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
            if element.arrowHead {
                drawArrowHead(ctx: ctx, from: from, to: to, color: strokeColor, width: lineWidth)
            }

        case .text:
            let position = CGPoint(x: element.x, y: element.y)
            let displayText = element.text ?? ""
            let text = Text(displayText)
                .font(LatticeTheme.bodyFont)
                .foregroundColor(strokeColor)
            ctx.draw(text, at: position, anchor: .topLeading)

        case .pencil:
            guard let points = element.points, points.count >= 2 else { return }
            var path = Path()
            path.move(to: points[0].cgPoint)
            for i in 1..<points.count {
                path.addLine(to: points[i].cgPoint)
            }
            ctx.stroke(path, with: .color(strokeColor), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawArrowHead(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let angle = atan2(dy, dx)
        let headLength: CGFloat = max(10, width * 4)

        let angle1 = angle + .pi - .pi / 6
        let angle2 = angle + .pi + .pi / 6

        let p1 = CGPoint(x: to.x + headLength * cos(angle1), y: to.y + headLength * sin(angle1))
        let p2 = CGPoint(x: to.x + headLength * cos(angle2), y: to.y + headLength * sin(angle2))

        var path1 = Path()
        path1.move(to: to)
        path1.addLine(to: p1)
        ctx.stroke(path1, with: .color(color), lineWidth: width)

        var path2 = Path()
        path2.move(to: to)
        path2.addLine(to: p2)
        ctx.stroke(path2, with: .color(color), lineWidth: width)
    }

    // MARK: - Drawing Preview

    @ViewBuilder
    private var drawingPreview: some View {
        switch whiteboard.activeTool {
        case .rect:
            let rect = previewRect
            Rectangle()
                .stroke(whiteboard.strokeColor, lineWidth: whiteboard.strokeWidth)
                .background(
                    whiteboard.hasFill
                        ? Rectangle().fill((whiteboard.fillColor ?? whiteboard.strokeColor).opacity(0.3))
                        : nil
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

        case .ellipse:
            let rect = previewRect
            Ellipse()
                .stroke(whiteboard.strokeColor, lineWidth: whiteboard.strokeWidth)
                .background(
                    whiteboard.hasFill
                        ? Ellipse().fill((whiteboard.fillColor ?? whiteboard.strokeColor).opacity(0.3))
                        : nil
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

        case .arrow:
            Path { path in
                path.move(to: whiteboard.drawStart)
                path.addLine(to: whiteboard.drawCurrent)
            }
            .stroke(whiteboard.strokeColor, lineWidth: whiteboard.strokeWidth)

        case .pencil:
            if whiteboard.pencilPoints.count >= 2 {
                Path { path in
                    path.move(to: whiteboard.pencilPoints[0])
                    for i in 1..<whiteboard.pencilPoints.count {
                        path.addLine(to: whiteboard.pencilPoints[i])
                    }
                }
                .stroke(whiteboard.strokeColor, style: StrokeStyle(lineWidth: whiteboard.strokeWidth, lineCap: .round, lineJoin: .round))
            }

        default:
            EmptyView()
        }
    }

    private var previewRect: CGRect {
        let minX = min(whiteboard.drawStart.x, whiteboard.drawCurrent.x)
        let minY = min(whiteboard.drawStart.y, whiteboard.drawCurrent.y)
        let w = abs(whiteboard.drawCurrent.x - whiteboard.drawStart.x)
        let h = abs(whiteboard.drawCurrent.y - whiteboard.drawStart.y)
        return CGRect(x: minX, y: minY, width: max(w, 1), height: max(h, 1))
    }

    // MARK: - Selection Overlay

    private func selectionOverlay(for element: CanvasElement) -> some View {
        let frame = element.frame
        return Rectangle()
            .stroke(
                LatticeTheme.mint,
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
            .frame(width: frame.width + 8, height: frame.height + 8)
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
    }

    // MARK: - Text Editor Overlay

    @ViewBuilder
    private var textEditorOverlay: some View {
        let pos = whiteboard.textEditPosition
        TextField("Type here...", text: Bindable(whiteboard).editingText)
            .textFieldStyle(.plain)
            .font(LatticeTheme.bodyFont)
            .foregroundStyle(LatticeTheme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LatticeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(LatticeTheme.mint, lineWidth: 1)
                    )
            )
            .position(x: pos.x + 60, y: pos.y)
            .onSubmit {
                whiteboard.commitText()
            }
    }

    // MARK: - Gesture Handling

    private func canvasPointFrom(location: CGPoint, in geo: GeometryProxy) -> CGPoint {
        // Convert screen location to canvas coordinates accounting for scale and offset
        let x = (location.x - whiteboard.canvasOffset.width) / whiteboard.canvasScale
        let y = (location.y - whiteboard.canvasOffset.height) / whiteboard.canvasScale
        return CGPoint(x: x, y: y)
    }

    private func canvasDragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let canvasPoint = canvasPointFrom(location: value.location, in: geo)
                let canvasStart = canvasPointFrom(location: value.startLocation, in: geo)

                switch whiteboard.activeTool {
                case .select:
                    if !isDraggingElement && !whiteboard.isDrawing {
                        // First movement -- decide: move element or pan canvas
                        if let hit = whiteboard.hitTest(point: canvasStart) {
                            isDraggingElement = true
                            if whiteboard.selectedElementId != hit.id {
                                whiteboard.selectedElementId = hit.id
                            }
                            whiteboard.pushUndo()
                            dragStartOffset = .zero
                        } else {
                            // Pan canvas
                            whiteboard.isDrawing = true // reuse flag to mark panning
                        }
                    }

                    if isDraggingElement {
                        let delta = CGSize(
                            width: canvasPoint.x - canvasStart.x - dragStartOffset.width,
                            height: canvasPoint.y - canvasStart.y - dragStartOffset.height
                        )
                        whiteboard.moveSelected(by: delta)
                        dragStartOffset = CGSize(
                            width: canvasPoint.x - canvasStart.x,
                            height: canvasPoint.y - canvasStart.y
                        )
                    } else {
                        // Pan
                        whiteboard.canvasOffset = CGSize(
                            width: whiteboard.canvasOffset.width + value.translation.width - (dragStartOffset.width),
                            height: whiteboard.canvasOffset.height + value.translation.height - (dragStartOffset.height)
                        )
                        dragStartOffset = CGSize(width: value.translation.width, height: value.translation.height)
                    }

                case .rect, .ellipse, .arrow:
                    if !whiteboard.isDrawing {
                        whiteboard.isDrawing = true
                        whiteboard.drawStart = canvasStart
                    }
                    whiteboard.drawCurrent = canvasPoint

                case .pencil:
                    if !whiteboard.isDrawing {
                        whiteboard.isDrawing = true
                        whiteboard.pencilPoints = [canvasStart]
                    }
                    whiteboard.pencilPoints.append(canvasPoint)

                case .text:
                    break
                }
            }
            .onEnded { value in
                switch whiteboard.activeTool {
                case .select:
                    if isDraggingElement {
                        whiteboard.commitMove()
                    }
                    isDraggingElement = false
                    whiteboard.isDrawing = false
                    dragStartOffset = .zero

                case .rect, .ellipse, .arrow:
                    whiteboard.finishDrawingShape()
                    dragStartOffset = .zero

                case .pencil:
                    whiteboard.finishPencilStroke()
                    dragStartOffset = .zero

                case .text:
                    break
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastMagnification * value.magnification
                whiteboard.canvasScale = max(0.3, min(3.0, newScale))
            }
            .onEnded { value in
                lastMagnification = whiteboard.canvasScale
            }
    }

    // MARK: - Tap Handling

    private func handleSingleTap(at location: CGPoint, in geo: GeometryProxy) {
        let canvasPoint = canvasPointFrom(location: location, in: geo)

        switch whiteboard.activeTool {
        case .select:
            if let hit = whiteboard.hitTest(point: canvasPoint) {
                whiteboard.selectedElementId = hit.id
            } else {
                whiteboard.selectedElementId = nil
            }

        case .text:
            if !whiteboard.isEditingText {
                whiteboard.placeText(at: canvasPoint)
            }

        default:
            break
        }
    }

    private func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
        let canvasPoint = canvasPointFrom(location: location, in: geo)

        if whiteboard.activeTool == .select {
            if let hit = whiteboard.hitTest(point: canvasPoint), hit.type == .text {
                whiteboard.beginEditingText(hit)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LatticeTheme.mint)
                    .frame(width: 6, height: 6)
                Text("\(whiteboard.elements.count)")
                    .font(LatticeTheme.monoFont)
                    .foregroundStyle(LatticeTheme.textSecondary)
                Text("elements")
                    .font(LatticeTheme.captionFont)
                    .foregroundStyle(LatticeTheme.textMuted)
            }

            if let canvas = whiteboard.selectedCanvas {
                HStack(spacing: 5) {
                    Text(canvas.displayTitle)
                        .font(LatticeTheme.captionFont)
                        .foregroundStyle(LatticeTheme.textMuted)
                        .lineLimit(1)
                }
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
