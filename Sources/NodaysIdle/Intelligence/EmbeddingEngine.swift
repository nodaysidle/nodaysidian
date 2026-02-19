import Foundation
import NaturalLanguage
import CoreData

actor EmbeddingEngine {
    private let embedding: NLEmbedding?

    init() {
        self.embedding = NLEmbedding.wordEmbedding(for: .english)
    }

    func generateEmbedding(for text: String) -> [Double]? {
        guard let embedding else { return nil }

        let words = text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 2 }

        guard !words.isEmpty else { return nil }

        var sumVector: [Double]? = nil
        var count = 0

        for word in words {
            if let vector = embedding.vector(for: word) {
                if sumVector == nil {
                    sumVector = vector
                } else {
                    for i in sumVector!.indices {
                        sumVector![i] += vector[i]
                    }
                }
                count += 1
            }
        }

        guard var result = sumVector, count > 0 else { return nil }
        for i in result.indices {
            result[i] /= Double(count)
        }

        // L2 normalize
        let norm = sqrt(result.reduce(0) { $0 + $1 * $1 })
        if norm > 0 {
            for i in result.indices {
                result[i] /= norm
            }
        }

        return result
    }

    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0
        for i in a.indices {
            dot += a[i] * b[i]
        }
        return dot // Already normalized
    }

    func embeddingToData(_ embedding: [Double]) -> Data {
        embedding.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    func dataToEmbedding(_ data: Data) -> [Double] {
        data.withUnsafeBytes { raw in
            let buffer = raw.bindMemory(to: Double.self)
            return Array(buffer)
        }
    }
}
