import Foundation
import CoreData

actor AutoEdgeDiscovery {
    private let embeddingEngine = EmbeddingEngine()
    private let similarityThreshold: Double = 0.65

    func discoverEdges(context: NSManagedObjectContext) async {
        let notes: [NoteSnapshot] = await MainActor.run {
            let req = NoteEntity.fetchAll()
            guard let entities = try? context.fetch(req) else { return [] }
            return entities.map { NoteSnapshot(id: $0.id, content: $0.content, existingEmbedding: $0.embedding) }
        }

        guard notes.count > 1 else { return }

        // Generate embeddings for notes that don't have them
        var embeddings: [UUID: [Double]] = [:]

        for note in notes {
            if let data = note.existingEmbedding {
                embeddings[note.id] = await embeddingEngine.dataToEmbedding(data)
            } else if let emb = await embeddingEngine.generateEmbedding(for: note.content) {
                embeddings[note.id] = emb
                // Save embedding back to Core Data
                let embData = await embeddingEngine.embeddingToData(emb)
                await MainActor.run {
                    let req = NoteEntity.fetchRequest()
                    req.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
                    if let entity = try? context.fetch(req).first {
                        entity.embedding = embData
                    }
                }
            }
        }

        // Find existing auto-edges to avoid duplicates
        let existingPairs: Set<String> = await MainActor.run {
            let edgeReq = EdgeEntity.fetchRequest()
            edgeReq.predicate = NSPredicate(format: "isAutoDiscovered == YES")
            guard let edges = try? context.fetch(edgeReq) else { return [] }
            return Set(edges.map { edgePairKey($0.sourceId, $0.targetId) })
        }

        // Compare all pairs
        var newEdges: [(UUID, UUID, Double)] = []
        let noteIds = Array(embeddings.keys)

        for i in 0..<noteIds.count {
            for j in (i + 1)..<noteIds.count {
                let idA = noteIds[i]
                let idB = noteIds[j]

                guard let embA = embeddings[idA],
                      let embB = embeddings[idB] else { continue }

                let pairKey = edgePairKey(idA, idB)
                guard !existingPairs.contains(pairKey) else { continue }

                let similarity = await embeddingEngine.cosineSimilarity(embA, embB)
                if similarity >= similarityThreshold {
                    newEdges.append((idA, idB, similarity))
                }
            }
        }

        // Create auto-edges
        if !newEdges.isEmpty {
            await MainActor.run {
                for (sourceId, targetId, strength) in newEdges {
                    _ = EdgeEntity.create(
                        in: context,
                        sourceId: sourceId,
                        targetId: targetId,
                        strength: strength,
                        isAuto: true,
                        label: "semantic-similarity"
                    )
                }
                try? context.save()
            }
        }
    }

    private nonisolated func edgePairKey(_ a: UUID, _ b: UUID) -> String {
        let sorted = [a.uuidString, b.uuidString].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }
}

private struct NoteSnapshot: Sendable {
    let id: UUID
    let content: String
    let existingEmbedding: Data?
}
