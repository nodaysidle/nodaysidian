import SwiftUI

struct GraphCanvasView: View {
    @Bindable var graph: GraphViewModel
    var vault: VaultViewModel

    @State private var draggedNodeId: UUID?
    @State private var hoverNodeId: UUID?

    var body: some View {
        ZStack {
            LatticeTheme.void
                .ignoresSafeArea()

            // Graph content
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                ZStack {
                    // Edges drawn in a flat Canvas — no gradients
                    Canvas { ctx, _ in
                        drawEdges(ctx: ctx, center: center)
                    }

                    ForEach(graph.nodes) { node in
                        nodeView(node: node, center: center)
                    }
                }
                .scaleEffect(graph.canvasScale)
                .offset(graph.canvasOffset)
                .gesture(panGesture)
                .gesture(magnifyGesture)
            }

            // Status bar overlay — bottom-left
            VStack {
                Spacer()
                HStack {
                    statusBar
                    Spacer()
                }
                .padding(16)
            }
        }
    }

    // MARK: - Edge Drawing (flat solid colors, no gradients)

    private func drawEdges(ctx: GraphicsContext, center: CGPoint) {
        for edge in graph.edges {
            guard
                let source = graph.nodes.first(where: { $0.id == edge.sourceId }),
                let target = graph.nodes.first(where: { $0.id == edge.targetId })
            else { continue }

            let from = CGPoint(x: center.x + source.x, y: center.y + source.y)
            let to   = CGPoint(x: center.x + target.x, y: center.y + target.y)

            var path = Path()
            path.move(to: from)
            path.addLine(to: to)

            // Auto-linked edges: lavender. Manual: mint.
            let color = edge.isAuto
                ? LatticeTheme.lavender.opacity(0.40)
                : LatticeTheme.mint.opacity(0.55)
            let lineWidth: CGFloat = edge.isAuto ? 1.0 : 1.5

            ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }

    // MARK: - Node View (flat solid circles, crisp ring)

    private func nodeView(node: GraphViewModel.GraphNode, center: CGPoint) -> some View {
        let radius   = LatticeTheme.nodeRadius(connectionCount: node.connectionCount)
        let isSelected = graph.selectedNodeId == node.id
        let isHovered  = hoverNodeId == node.id
        let fillColor  = LatticeTheme.ripenessColor(node.ripeness)

        return ZStack {
            // Selection / hover halo — flat, solid
            if isSelected || isHovered {
                Circle()
                    .fill(fillColor.opacity(isSelected ? 0.22 : 0.14))
                    .frame(width: radius * 4, height: radius * 4)
            }

            // Node body — solid flat fill
            Circle()
                .fill(fillColor)
                .frame(width: radius * 2, height: radius * 2)

            // Crisp ring
            Circle()
                .strokeBorder(
                    isSelected
                        ? LatticeTheme.textPrimary.opacity(0.9)
                        : fillColor.opacity(0.6),
                    lineWidth: isSelected ? 2 : 1
                )
                .frame(width: radius * 2, height: radius * 2)

            // Hover / selected label
            if isHovered || isSelected {
                Text(node.title)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundStyle(LatticeTheme.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(LatticeTheme.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(LatticeTheme.border, lineWidth: 1)
                            }
                    }
                    .offset(y: -(radius + 16))
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .bottom)))
            }
        }
        .position(x: center.x + node.x, y: center.y + node.y)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                hoverNodeId = hovering ? node.id : nil
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                graph.selectNode(node.id)
                vault.selectedNote = vault.notes.first { $0.id == node.id }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let idx = graph.nodes.firstIndex(where: { $0.id == node.id }) {
                        graph.nodes[idx].x  = value.location.x - center.x
                        graph.nodes[idx].y  = value.location.y - center.y
                        graph.nodes[idx].vx = 0
                        graph.nodes[idx].vy = 0
                    }
                }
        )
        .animation(.easeOut(duration: 0.08), value: node.x)
        .animation(.easeOut(duration: 0.08), value: node.y)
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                graph.canvasOffset = value.translation
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                graph.canvasScale = max(0.3, min(3.0, value.magnification))
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

            if graph.isSimulating {
                HStack(spacing: 5) {
                    Circle()
                        .fill(LatticeTheme.amber)
                        .frame(width: 5, height: 5)
                        .modifier(PulseModifier())
                    Text("simulating")
                        .font(LatticeTheme.captionFont)
                        .foregroundStyle(LatticeTheme.textMuted)
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

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
