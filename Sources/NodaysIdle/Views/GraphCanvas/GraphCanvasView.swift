import SwiftUI

struct GraphCanvasView: View {
    @Bindable var graph: GraphViewModel
    var vault: VaultViewModel

    @State private var hoverNodeId: UUID?
    @State private var dragMode: CanvasDragMode = .none
    @State private var lastMagnification: CGFloat = 1.0

    private enum CanvasDragMode: Equatable {
        case none
        case panning
        case node(UUID)
    }

    var body: some View {
        ZStack {
            LatticeTheme.void
                .ignoresSafeArea()

            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let nodeLookup = graph.nodeLookup()
                let highlightedId = graph.selectedNodeId ?? hoverNodeId

                ZStack {
                    Canvas { ctx, _ in
                        drawEdges(ctx: ctx, center: center, nodeLookup: nodeLookup)
                        drawNodes(ctx: ctx, center: center, highlightedId: highlightedId)
                    }
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            hoverNodeId = nodeAt(screenPoint: location, center: center)?.id
                        case .ended:
                            hoverNodeId = nil
                        }
                    }
                    .onTapGesture(count: 2, coordinateSpace: .local) { location in
                        if let hit = nodeAt(screenPoint: location, center: center) {
                            vault.selectedNote = vault.notes.first { $0.id == hit.id }
                            NotificationCenter.default.post(name: .openNoteInEditor, object: hit.id)
                        }
                    }
                    .onTapGesture(count: 1, coordinateSpace: .local) { location in
                        if let hit = nodeAt(screenPoint: location, center: center) {
                            graph.selectNode(hit.id)
                            vault.selectedNote = vault.notes.first { $0.id == hit.id }
                        } else {
                            graph.selectNode(nil)
                        }
                    }
                    .gesture(canvasDragGesture(center: center))
                }
                .scaleEffect(graph.canvasScale)
                .offset(graph.canvasOffset)
                .gesture(magnifyGesture)
            }

            VStack {
                Spacer()
                HStack {
                    statusBar
                    Spacer()
                }
                .padding(16)
            }
        }
        .onAppear {
            graph.setGraphVisible(true)
        }
        .onDisappear {
            graph.setGraphVisible(false)
        }
    }

    // MARK: - Drawing

    private func drawEdges(
        ctx: GraphicsContext,
        center: CGPoint,
        nodeLookup: [UUID: GraphViewModel.GraphNode]
    ) {
        for edge in graph.edges {
            guard
                let source = nodeLookup[edge.sourceId],
                let target = nodeLookup[edge.targetId]
            else { continue }

            let from = CGPoint(x: center.x + source.x, y: center.y + source.y)
            let to = CGPoint(x: center.x + target.x, y: center.y + target.y)

            var path = Path()
            path.move(to: from)
            path.addLine(to: to)

            let color = edge.isAuto
                ? LatticeTheme.lavender.opacity(0.40)
                : LatticeTheme.mint.opacity(0.55)
            let lineWidth: CGFloat = edge.isAuto ? 1.0 : 1.5

            ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }

    private func drawNodes(
        ctx: GraphicsContext,
        center: CGPoint,
        highlightedId: UUID?
    ) {
        for node in graph.nodes {
            let radius = LatticeTheme.nodeRadius(connectionCount: node.connectionCount)
            let isSelected = graph.selectedNodeId == node.id
            let isHovered = hoverNodeId == node.id
            let fillColor = LatticeTheme.ripenessColor(node.ripeness)
            let position = CGPoint(x: center.x + node.x, y: center.y + node.y)
            let diameter = radius * 2

            if isSelected || isHovered {
                let haloRect = CGRect(
                    x: position.x - radius * 2,
                    y: position.y - radius * 2,
                    width: diameter * 2,
                    height: diameter * 2
                )
                ctx.fill(
                    Path(ellipseIn: haloRect),
                    with: .color(fillColor.opacity(isSelected ? 0.22 : 0.14))
                )
            }

            let bodyRect = CGRect(
                x: position.x - radius,
                y: position.y - radius,
                width: diameter,
                height: diameter
            )
            ctx.fill(Path(ellipseIn: bodyRect), with: .color(fillColor))

            let ringColor = isSelected
                ? LatticeTheme.textPrimary.opacity(0.9)
                : fillColor.opacity(0.6)
            ctx.stroke(
                Path(ellipseIn: bodyRect),
                with: .color(ringColor),
                lineWidth: isSelected ? 2 : 1
            )

            if isSelected || isHovered {
                let label = Text(node.title)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(LatticeTheme.textPrimary)
                ctx.draw(label, at: CGPoint(x: position.x, y: position.y - radius - 16), anchor: .bottom)
            }
        }
    }

    // MARK: - Hit Testing

    private func nodeAt(screenPoint: CGPoint, center: CGPoint) -> GraphViewModel.GraphNode? {
        for node in graph.nodes.reversed() {
            let radius = LatticeTheme.nodeRadius(connectionCount: node.connectionCount)
            let nodeCenter = CGPoint(x: center.x + node.x, y: center.y + node.y)
            let dx = screenPoint.x - nodeCenter.x
            let dy = screenPoint.y - nodeCenter.y
            if (dx * dx + dy * dy) <= radius * radius {
                return node
            }
        }
        return nil
    }

    // MARK: - Gestures

    private func canvasDragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragMode == .none {
                    if let hit = nodeAt(screenPoint: value.startLocation, center: center) {
                        dragMode = .node(hit.id)
                        graph.selectNode(hit.id)
                        vault.selectedNote = vault.notes.first { $0.id == hit.id }
                    } else {
                        dragMode = .panning
                    }
                }

                switch dragMode {
                case .node(let nodeId):
                    graph.updateNodePosition(
                        id: nodeId,
                        x: value.location.x - center.x,
                        y: value.location.y - center.y
                    )
                case .panning:
                    graph.canvasOffset = CGSize(
                        width: graph.savedOffset.width + value.translation.width,
                        height: graph.savedOffset.height + value.translation.height
                    )
                case .none:
                    break
                }
            }
            .onEnded { _ in
                if case .panning = dragMode {
                    graph.savedOffset = graph.canvasOffset
                }
                dragMode = .none
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastMagnification * value.magnification
                graph.canvasScale = max(0.3, min(3.0, newScale))
            }
            .onEnded { _ in
                lastMagnification = graph.canvasScale
            }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                Circle()
                    .fill(LatticeTheme.mint)
                    .frame(width: 5, height: 5)
                Text("\(graph.nodes.count)")
                    .font(LatticeTheme.monoFont)
                    .foregroundStyle(LatticeTheme.textSecondary)
                Text("nodes")
                    .font(LatticeTheme.captionFont)
                    .foregroundStyle(LatticeTheme.textMuted)
            }

            HStack(spacing: 5) {
                Rectangle()
                    .fill(LatticeTheme.lavender)
                    .frame(width: 8, height: 1)
                Text("\(graph.edges.count)")
                    .font(LatticeTheme.monoFont)
                    .foregroundStyle(LatticeTheme.textSecondary)
                Text("edges")
                    .font(LatticeTheme.captionFont)
                    .foregroundStyle(LatticeTheme.textMuted)
            }

            Button {
                graph.toggleSimulation()
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(graph.isSimulating ? LatticeTheme.amber : LatticeTheme.textMuted)
                        .frame(width: 5, height: 5)
                        .modifier(graph.isSimulating ? PulseModifier() : PulseModifier(disabled: true))
                    Text(graph.isSimulating ? "simulating" : "frozen")
                        .font(LatticeTheme.captionFont)
                        .foregroundStyle(LatticeTheme.textMuted)
                }
            }
            .buttonStyle(.plain)
            .help(graph.isSimulating ? "Freeze layout" : "Resume simulation")
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

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    var disabled: Bool = false
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(disabled ? 1.0 : (isPulsing ? 0.3 : 1.0))
            .animation(
                disabled ? nil : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                if !disabled { isPulsing = true }
            }
    }
}
