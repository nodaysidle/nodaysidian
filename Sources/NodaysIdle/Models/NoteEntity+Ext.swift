import CoreData
import Foundation

@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var ripenessScore: Double
    @NSManaged public var posX: Double
    @NSManaged public var posY: Double
    @NSManaged public var embedding: Data?
    @NSManaged public var sourcePath: String?
}

extension NoteEntity {
    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var snippet: String {
        let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count <= 120 { return clean }
        return String(clean.prefix(120)) + "..."
    }

    var daysSinceModified: Double {
        guard let mod = modifiedAt else { return 999 }
        return Date().timeIntervalSince(mod) / 86400.0
    }

    static func create(
        in context: NSManagedObjectContext,
        title: String = "Untitled",
        content: String = ""
    ) -> NoteEntity {
        let note = NoteEntity(context: context)
        note.id = UUID()
        note.title = title
        note.content = content
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.ripenessScore = 0.0
        note.posX = Double.random(in: -300...300)
        note.posY = Double.random(in: -300...300)
        return note
    }
}

extension NoteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }

    @nonobjc public class func fetchAll() -> NSFetchRequest<NoteEntity> {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \NoteEntity.modifiedAt, ascending: false)]
        return req
    }
}
