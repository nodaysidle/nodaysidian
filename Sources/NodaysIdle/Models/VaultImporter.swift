import Foundation
import CoreData

struct VaultImporter: Sendable {
    struct ImportResult: Sendable {
        let notesImported: Int
        let linksDiscovered: Int
    }

    @MainActor
    static func importVault(at url: URL, context: NSManagedObjectContext) throws -> ImportResult {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            throw ImportError.directoryNotFound
        }

        let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var mdFiles: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "md" {
                mdFiles.append(fileURL)
            }
        }

        var noteMap: [String: NoteEntity] = [:]
        var linkPairs: [(String, String)] = []

        for fileURL in mdFiles {
            let rawContent = try String(contentsOf: fileURL, encoding: .utf8)
            let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
            let baseName = fileURL.deletingPathExtension().lastPathComponent

            let (content, frontMatter) = parseFrontMatter(rawContent)
            let title = frontMatter["title"] ?? baseName

            let note = NoteEntity.create(in: context, title: title, content: content)
            note.sourcePath = relativePath
            noteMap[baseName.lowercased()] = note

            let links = extractWikiLinks(from: content)
            for link in links {
                linkPairs.append((baseName.lowercased(), link.lowercased()))
            }
        }

        var edgeCount = 0
        for (sourceName, targetName) in linkPairs {
            guard let source = noteMap[sourceName],
                  let target = noteMap[targetName] else { continue }
            _ = EdgeEntity.create(
                in: context,
                sourceId: source.id,
                targetId: target.id,
                strength: 0.8,
                isAuto: false,
                label: "wiki-link"
            )
            edgeCount += 1
        }

        try context.save()
        return ImportResult(notesImported: noteMap.count, linksDiscovered: edgeCount)
    }

    private static func extractWikiLinks(from text: String) -> [String] {
        let pattern = #"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range]).trimmingCharacters(in: .whitespaces)
        }
    }

    private static func parseFrontMatter(_ raw: String) -> (content: String, meta: [String: String]) {
        var meta: [String: String] = [:]
        var content = raw

        if raw.hasPrefix("---") {
            let parts = raw.split(separator: "---", maxSplits: 2, omittingEmptySubsequences: false)
            if parts.count >= 3 {
                let yamlBlock = String(parts[1])
                content = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                for line in yamlBlock.split(separator: "\n") {
                    let kv = line.split(separator: ":", maxSplits: 1)
                    if kv.count == 2 {
                        let key = kv[0].trimmingCharacters(in: .whitespaces).lowercased()
                        let val = kv[1].trimmingCharacters(in: .whitespaces)
                        meta[key] = val
                    }
                }
            }
        }
        return (content, meta)
    }

    enum ImportError: LocalizedError {
        case directoryNotFound
        var errorDescription: String? {
            "The selected directory was not found."
        }
    }
}
