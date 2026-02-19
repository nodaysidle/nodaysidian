import Foundation
import CoreData

struct RipenessEngine: Sendable {
    // Ripeness = how "ready" a note is for attention/connection
    // Based on: time decay, connection density, content depth

    @MainActor
    static func computeRipeness(context: NSManagedObjectContext) {
        let noteReq = NoteEntity.fetchAll()
        let edgeReq = EdgeEntity.fetchRequest()

        guard let notes = try? context.fetch(noteReq),
              let edges = try? context.fetch(edgeReq) else { return }

        let edgeCountMap = edges.reduce(into: [UUID: Int]()) { map, e in
            map[e.sourceId, default: 0] += 1
            map[e.targetId, default: 0] += 1
        }

        let maxEdges = Double(edgeCountMap.values.max() ?? 1)

        for note in notes {
            let daysSince = note.daysSinceModified
            let connections = Double(edgeCountMap[note.id] ?? 0)
            let contentLength = Double(note.content.count)

            // Time decay: notes that haven't been touched become more "ripe"
            // Peaks around 7-14 days, then slowly decays
            let timeSignal = timeDecayCurve(days: daysSince)

            // Connection density: more connections = less isolated = ripe for bridging
            let connectionSignal = min(connections / max(maxEdges, 1), 1.0)

            // Content depth: longer notes have more potential
            let depthSignal = min(contentLength / 2000.0, 1.0)

            // Weighted combination
            let ripeness = (timeSignal * 0.45) + (connectionSignal * 0.30) + (depthSignal * 0.25)
            note.ripenessScore = max(0, min(1, ripeness))
        }

        try? context.save()
    }

    private static func timeDecayCurve(days: Double) -> Double {
        // Bell curve peaking at ~10 days
        // Notes edited today: low ripeness (fresh, no need to revisit)
        // Notes 7-14 days old: high ripeness (spaced repetition sweet spot)
        // Notes 30+ days old: moderate ripeness (still worth revisiting)
        // Notes 90+ days old: lower ripeness (may be stale)

        if days < 1 { return 0.1 }
        if days < 3 { return 0.3 }

        let peak = 10.0
        let sigma = 12.0
        let bellValue = exp(-pow(days - peak, 2) / (2 * sigma * sigma))

        // Add a long-tail floor so old notes don't vanish
        let floor = 0.2
        return floor + (1.0 - floor) * bellValue
    }
}
