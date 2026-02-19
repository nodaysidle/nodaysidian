import SwiftUI
import CoreData

@MainActor
@Observable
final class VaultViewModel {
    var notes: [NoteEntity] = []
    var selectedNote: NoteEntity?
    var searchText: String = ""
    var isImporting: Bool = false
    var importMessage: String?
    var showImportPanel: Bool = false

    private var context: NSManagedObjectContext?

    var filteredNotes: [NoteEntity] {
        guard !searchText.isEmpty else { return notes }
        let query = searchText.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    func bind(context: NSManagedObjectContext) {
        self.context = context
        reload()
    }

    func reload() {
        guard let context else { return }
        let req = NoteEntity.fetchAll()
        notes = (try? context.fetch(req)) ?? []
    }

    func createNote() {
        guard let context else { return }
        let note = NoteEntity.create(in: context, title: "Untitled", content: "")
        try? context.save()
        notes.insert(note, at: 0)
        selectedNote = note
    }

    func deleteNote(_ note: NoteEntity) {
        guard let context else { return }
        // Delete associated edges
        let edgeReq = EdgeEntity.fetchRequest()
        if let edges = try? context.fetch(edgeReq) {
            for edge in edges where edge.sourceId == note.id || edge.targetId == note.id {
                context.delete(edge)
            }
        }
        context.delete(note)
        try? context.save()
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
    }

    func saveNote() {
        guard let context else { return }
        selectedNote?.modifiedAt = Date()
        try? context.save()
    }

    func importVault(url: URL) {
        guard let context else { return }
        isImporting = true
        importMessage = nil

        do {
            let result = try VaultImporter.importVault(at: url, context: context)
            importMessage = "Imported \(result.notesImported) notes, \(result.linksDiscovered) links"
            reload()
        } catch {
            importMessage = "Import failed: \(error.localizedDescription)"
        }
        isImporting = false
    }
}
