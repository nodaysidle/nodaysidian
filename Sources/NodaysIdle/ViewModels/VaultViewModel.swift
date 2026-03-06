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
    var showDeleteConfirmation: Bool = false
    var noteToDelete: NoteEntity?

    private var context: NSManagedObjectContext?
    private var importMessageTask: Task<Void, Never>?

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
        do { try context.save() } catch {
            print("[Nodaysidian] Failed to save new note: \(error.localizedDescription)")
        }
        notes.insert(note, at: 0)
        selectedNote = note
    }

    func confirmDelete(_ note: NoteEntity) {
        noteToDelete = note
        showDeleteConfirmation = true
    }

    func deleteNote(_ note: NoteEntity) {
        guard let context else { return }
        let noteId = note.id

        // Clear selection BEFORE deletion to prevent SwiftUI from
        // accessing .id on a deleted Core Data object (UUID bridge crash)
        if selectedNote?.id == noteId {
            selectedNote = nil
        }
        notes.removeAll { $0.id == noteId }

        // Now safe to delete from Core Data
        let edgeReq = EdgeEntity.fetchRequest()
        if let edges = try? context.fetch(edgeReq) {
            for edge in edges where edge.sourceId == noteId || edge.targetId == noteId {
                context.delete(edge)
            }
        }
        context.delete(note)
        do { try context.save() } catch {
            print("[Nodaysidian] Failed to delete note: \(error.localizedDescription)")
        }
    }

    func saveNote() {
        guard let context else { return }
        selectedNote?.modifiedAt = Date()
        do { try context.save() } catch {
            print("[Nodaysidian] Failed to save note: \(error.localizedDescription)")
        }
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

        // Auto-clear import message after 5 seconds
        importMessageTask?.cancel()
        importMessageTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            importMessage = nil
        }
    }
}
