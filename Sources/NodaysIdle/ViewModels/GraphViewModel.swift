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
    var isGraphVisible: Bool = false

    // Accumulated gesture state
    var savedOffset: CGSize = .zero
    var savedScale: CGFloat = 1.0

    private var context: NSManagedObjectContext?
    private var simulationTimer: Timer?
    private var nodeIndex: [UUID: Int] = [:]
    private var alpha: Double = 1.0
    private var needsReload = true
    private var simulationWasPaused = false

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
        invalidate()
        reload()
    }

    func invalidate() {
        needsReload = true
    }

    func refreshIfNeeded() {
        guard needsReload else { return }
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

        let existingPositions = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, ($0.x, $0.y, $0.vx, $0.vy)) })

        self.nodes = notes.map { note in
            let existing = existingPositions[note.id]
            return GraphNode(
                id: note.id,
                title: note.displayTitle,
                x: existing?.0 ?? note.posX,
                y: existing?.1 ?? note.posY,
                vx: existing?.2 ?? 0,
                vy: existing?.3 ?? 0,
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

        needsReload = false
        rebuildIndex()

        if isGraphVisible && isSimulating {
            startSimulation()
        }
    }

    private func rebuildIndex() {
        nodeIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })
    }

    func setGraphVisible(_ visible: Bool) {
        guard isGraphVisible != visible else { return }
        isGraphVisible = visible

        if visible {
            refreshIfNeeded()
            if isSimulating || simulationWasPaused {
                resumeSimulation()
            }
        } else {
            pauseSimulation()
        }
    }

    // MARK: - Force-Directed Simulation with Cooling

    func startSimulation() {
        guard isGraphVisible else {
            isSimulating = true
            simulationWasPaused = true
            return
        }

        simulationTimer?.invalidate()
        alpha = 1.0
        isSimulating = true
        simulationWasPaused = false

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.simulationStep()
            }
        }
    }

    func pauseSimulation() {
        simulationWasPaused = isSimulating
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    func resumeSimulation() {
        guard isGraphVisible, simulationTimer == nil else { return }
        isSimulating = true
        simulationWasPaused = false
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.simulationStep()
            }
        }
    }

    func stopSimulation() {
        isSimulating = false
        simulationWasPaused = false
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

    private struct GridKey: Hashable {
        let x: Int
        let y: Int
    }

    private func simulationStep() {
        guard nodes.count > 1 else { return }

        let repulsion: Double = 8000
        let attraction: Double = 0.005
        let damping: Double = 0.85
        let centerPull: Double = 0.01
        let alphaDecay: Double = 0.995
        let alphaMin: Double = 0.005
        let cellSize: Double = 100

        alpha *= alphaDecay
        if alpha < alphaMin {
            stopSimulation()
            return
        }

        var updated = nodes

        var grid: [GridKey: [Int]] = [:]
        for i in updated.indices {
            let key = GridKey(
                x: Int(updated[i].x / cellSize),
                y: Int(updated[i].y / cellSize)
            )
            grid[key, default: []].append(i)
        }

        for i in updated.indices {
            var fx = 0.0
            var fy = 0.0
            let cellX = Int(updated[i].x / cellSize)
            let cellY = Int(updated[i].y / cellSize)

            for dx in -1...1 {
                for dy in -1...1 {
                    let key = GridKey(x: cellX + dx, y: cellY + dy)
                    guard let bucket = grid[key] else { continue }

                    for j in bucket where i != j {
                        let nodeDx = updated[i].x - updated[j].x
                        let nodeDy = updated[i].y - updated[j].y
                        let dist = max(sqrt(nodeDx * nodeDx + nodeDy * nodeDy), 1)
                        let force = repulsion / (dist * dist)
                        fx += (nodeDx / dist) * force
                        fy += (nodeDy / dist) * force
                    }
                }
            }

            fx -= updated[i].x * centerPull
            fy -= updated[i].y * centerPull

            updated[i].vx = (updated[i].vx + fx * alpha) * damping
            updated[i].vy = (updated[i].vy + fy * alpha) * damping
        }

        for edge in edges {
            guard let si = nodeIndex[edge.sourceId],
                  let ti = nodeIndex[edge.targetId],
                  si < updated.count, ti < updated.count else { continue }

            let dx = updated[ti].x - updated[si].x
            let dy = updated[ti].y - updated[si].y
            let force = attraction * edge.strength * alpha

            updated[si].vx += dx * force
            updated[si].vy += dy * force
            updated[ti].vx -= dx * force
            updated[ti].vy -= dy * force
        }

        for i in updated.indices {
            updated[i].x += updated[i].vx
            updated[i].y += updated[i].vy
        }

        nodes = updated
    }

    func selectNode(_ id: UUID?) {
        selectedNodeId = id
    }

    func nodeLookup() -> [UUID: GraphNode] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    }

    func updateNodePosition(id: UUID, x: Double, y: Double) {
        guard let idx = nodeIndex[id] else { return }
        var updated = nodes
        updated[idx].x = x
        updated[idx].y = y
        updated[idx].vx = 0
        updated[idx].vy = 0
        nodes = updated
    }

    func savePositions() {
        guard let context else { return }
        let req = NoteEntity.fetchAll()
        guard let notes = try? context.fetch(req) else { return }

        let positions = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, ($0.x, $0.y)) })
        for note in notes {
            if let position = positions[note.id] {
                note.posX = position.0
                note.posY = position.1
            }
        }
        do {
            try context.save()
        } catch {
            print("[Nodaysidian] Failed to save graph positions: \(error.localizedDescription)")
        }
    }
}
