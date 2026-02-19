import CoreData
import Foundation

@MainActor
final class PersistenceController: Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        let model = Self.buildModel()
        container = NSPersistentContainer(name: "NodaysIdle", managedObjectModel: model)

        let storeURL = Self.storeURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    private static func storeURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NodaysIdle", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("NodaysIdle.sqlite")
    }

    // MARK: - Programmatic Core Data Model

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- NoteEntity ---
        let noteEntity = NSEntityDescription()
        noteEntity.name = "NoteEntity"
        noteEntity.managedObjectClassName = "NoteEntity"

        let noteId = NSAttributeDescription()
        noteId.name = "id"
        noteId.attributeType = .UUIDAttributeType
        noteId.isOptional = false

        let noteTitle = NSAttributeDescription()
        noteTitle.name = "title"
        noteTitle.attributeType = .stringAttributeType
        noteTitle.defaultValue = "Untitled"

        let noteContent = NSAttributeDescription()
        noteContent.name = "content"
        noteContent.attributeType = .stringAttributeType
        noteContent.defaultValue = ""

        let noteCreatedAt = NSAttributeDescription()
        noteCreatedAt.name = "createdAt"
        noteCreatedAt.attributeType = .dateAttributeType

        let noteModifiedAt = NSAttributeDescription()
        noteModifiedAt.name = "modifiedAt"
        noteModifiedAt.attributeType = .dateAttributeType

        let noteRipeness = NSAttributeDescription()
        noteRipeness.name = "ripenessScore"
        noteRipeness.attributeType = .doubleAttributeType
        noteRipeness.defaultValue = 0.0

        let noteX = NSAttributeDescription()
        noteX.name = "posX"
        noteX.attributeType = .doubleAttributeType
        noteX.defaultValue = 0.0

        let noteY = NSAttributeDescription()
        noteY.name = "posY"
        noteY.attributeType = .doubleAttributeType
        noteY.defaultValue = 0.0

        let noteEmbedding = NSAttributeDescription()
        noteEmbedding.name = "embedding"
        noteEmbedding.attributeType = .binaryDataAttributeType
        noteEmbedding.isOptional = true

        let noteSourcePath = NSAttributeDescription()
        noteSourcePath.name = "sourcePath"
        noteSourcePath.attributeType = .stringAttributeType
        noteSourcePath.isOptional = true

        noteEntity.properties = [
            noteId, noteTitle, noteContent, noteCreatedAt, noteModifiedAt,
            noteRipeness, noteX, noteY, noteEmbedding, noteSourcePath
        ]

        // --- EdgeEntity ---
        let edgeEntity = NSEntityDescription()
        edgeEntity.name = "EdgeEntity"
        edgeEntity.managedObjectClassName = "EdgeEntity"

        let edgeId = NSAttributeDescription()
        edgeId.name = "id"
        edgeId.attributeType = .UUIDAttributeType
        edgeId.isOptional = false

        let edgeSourceId = NSAttributeDescription()
        edgeSourceId.name = "sourceId"
        edgeSourceId.attributeType = .UUIDAttributeType

        let edgeTargetId = NSAttributeDescription()
        edgeTargetId.name = "targetId"
        edgeTargetId.attributeType = .UUIDAttributeType

        let edgeStrength = NSAttributeDescription()
        edgeStrength.name = "strength"
        edgeStrength.attributeType = .doubleAttributeType
        edgeStrength.defaultValue = 0.5

        let edgeIsAuto = NSAttributeDescription()
        edgeIsAuto.name = "isAutoDiscovered"
        edgeIsAuto.attributeType = .booleanAttributeType
        edgeIsAuto.defaultValue = false

        let edgeCreatedAt = NSAttributeDescription()
        edgeCreatedAt.name = "createdAt"
        edgeCreatedAt.attributeType = .dateAttributeType

        let edgeLabel = NSAttributeDescription()
        edgeLabel.name = "label"
        edgeLabel.attributeType = .stringAttributeType
        edgeLabel.isOptional = true

        edgeEntity.properties = [
            edgeId, edgeSourceId, edgeTargetId, edgeStrength,
            edgeIsAuto, edgeCreatedAt, edgeLabel
        ]

        // --- CanvasEntity ---
        let canvasEntity = NSEntityDescription()
        canvasEntity.name = "CanvasEntity"
        canvasEntity.managedObjectClassName = "CanvasEntity"

        let canvasId = NSAttributeDescription()
        canvasId.name = "id"
        canvasId.attributeType = .UUIDAttributeType
        canvasId.isOptional = false

        let canvasTitle = NSAttributeDescription()
        canvasTitle.name = "title"
        canvasTitle.attributeType = .stringAttributeType
        canvasTitle.defaultValue = "Untitled Canvas"

        let canvasElements = NSAttributeDescription()
        canvasElements.name = "elementsData"
        canvasElements.attributeType = .binaryDataAttributeType
        canvasElements.isOptional = true

        let canvasCreatedAt = NSAttributeDescription()
        canvasCreatedAt.name = "createdAt"
        canvasCreatedAt.attributeType = .dateAttributeType

        let canvasModifiedAt = NSAttributeDescription()
        canvasModifiedAt.name = "modifiedAt"
        canvasModifiedAt.attributeType = .dateAttributeType

        let canvasLinkedNote = NSAttributeDescription()
        canvasLinkedNote.name = "linkedNoteId"
        canvasLinkedNote.attributeType = .UUIDAttributeType
        canvasLinkedNote.isOptional = true

        canvasEntity.properties = [
            canvasId, canvasTitle, canvasElements,
            canvasCreatedAt, canvasModifiedAt, canvasLinkedNote
        ]

        model.entities = [noteEntity, edgeEntity, canvasEntity]
        return model
    }

    // MARK: - Convenience

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}
