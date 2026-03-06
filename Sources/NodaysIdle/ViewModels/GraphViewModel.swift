import SwiftUI
import CoreData
import Combine

@MainActor
@Observable
final class GraphViewModel {
    var nodes: [GraphNode] = []
    var edges: [GraphEdge] = []
    var selectedNodeId: UUID?
    var searchText: String = ""
    var canvasOffset: CGSize = .zero
    var canvasScale: CGFloat = 1.0
    var isSimulating: Bool = true

    // Accumulated gesture state
    var savedOffset: CGSize = .zero
    var savedScale: CGFloat = 1.0

    private var context: NSManagedObjectContext?
    private var simulationTimer: Timer?
    private var nodeIndex: [UUID: Int] = [:]
    private var alpha: Double = 1.0

    struct GraphNode: Identifiable, Sendable {
        let id: UUID
        var title: String
        var x: Double
        var y: Double
        var vx: Double = 0
        var vy: Double = 0
        var ripeness: Double
        var connectionCount: Int = 0
    }

    struct GraphEdge: Identifiable, Sendable {
        let id: UUID
        let sourceId: UUID
        let targetId: UUID
        let strength: Double
        let isAuto: Bool
    }

    func bind(context: NSManagedObjectContext) {
        self.context = context
        reload()
    }

    func reload() {
        guard let context else { return }

        let noteReq = NoteEntity.fetchAll()
        let edgeReq = EdgeEntity.fetchRequest()

        guard let notes = try? context.fetch(noteReq),
              let edgeEntities = try? context.fetch(edgeReq) else { return }

        let edgeCountMap = edgeEntities.reduce(into: [UUID: Int]()) { map, e in
            map[e.sourceId, default: 0] += 1
            map[e.targetId, default: 0] += 1
        }

        self.nodes = notes.map { note in
            GraphNode(
                id: note.id,
                title: note.displayTitle,
                x: note.posX,
                y: note.posY,
                ripeness: note.ripenessScore,
                connectionCount: edgeCountMap[note.id] ?? 0
            )
        }

        self.edges = edgeEntities.map { e in
            GraphEdge(
                id: e.id,
                sourceId: e.sourceId,
                targetId: e.targetId,
                strength: e.strength,
                isAuto: e.isAutoDiscovered
            )
        }

        rebuildIndex()
        startSimulation()
    }

    private func rebuildIndex() {
        nodeIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })
    }

    // MARK: - Force-Directed Simulation with Cooling

    func startSimulation() {
        simulationTimer?.invalidate()
        alpha = 1.0
        isSimulating = true

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.simulationStep()
            }
        }
    }

    func stopSimulation() {
        isSimulating = false
        simulationTimer?.invalidate()
        simulationTimer = nil
        savePositions()
    }

    func toggleSimulation() {
        if isSimulating {
            stopSimulation()
        } else {
            startSimulation()
        }
    }

    private func simulationStep() {
        guard nodes.count > 1 else { return }

        let repulsion: Double = 8000
        let attraction: Double = 0.005
        let damping: Double = 0.85
        let centerPull: Double = 0.01
        let alphaDecay: Double = 0.995
        let alphaMin: Double = 0.005

        // Apply cooling
        alpha *= alphaDecay
        if alpha < alphaMin {
            stopSimulation()
            return
        }

        for i in nodes.indices {
            var fx = 0.0, fy = 0.0

            // Repulsion between all nodes
            for j in nodes.indices where i != j {
                let dx = nodes[i].x - nodes[j].x
                let dy = nodes[i].y - nodes[j].y
                let dist = max(sqrt(dx * dx + dy * dy), 1)
                let force = repulsion / (dist * dist)
                fx += (dx / dist) * force
                fy += (dy / dist) * force
            }

            // Center gravity
            fx -= nodes[i].x * centerPull
            fy -= nodes[i].y * centerPull

            nodes[i].vx = (nodes[i].vx + fx * alpha) * damping
            nodes[i].vy = (nodes[i].vy + fy * alpha) * damping
        }

        // Attraction along edges — O(1) lookups via index
        for edge in edges {
            guard let si = nodeIndex[edge.sourceId],
                  let ti = nodeIndex[edge.targetId],
                  si < nodes.count, ti < nodes.count else { continue }

            let dx = nodes[ti].x - nodes[si].x
            let dy = nodes[ti].y - nodes[si].y
            let force = attraction * edge.strength * alpha

            nodes[si].vx += dx * force
            nodes[si].vy += dy * force
            nodes[ti].vx -= dx * force
            nodes[ti].vy -= dy * force
        }

        // Apply velocities
        for i in nodes.indices {
            nodes[i].x += nodes[i].vx
            nodes[i].y += nodes[i].vy
        }
    }

    func selectNode(_ id: UUID?) {
        selectedNodeId = id
    }

    func savePositions() {
        guard let context else { return }
        let req = NoteEntity.fetchAll()
        guard let notes = try? context.fetch(req) else { return }

        for note in notes {
            if let node = nodes.first(where: { $0.id == note.id }) {
                note.posX = node.x
                note.posY = node.y
            }
        }
        do {
            try context.save()
        } catch {
            print("[Nodaysidian] Failed to save graph positions: \(error.localizedDescription)")
        }
    }
}
