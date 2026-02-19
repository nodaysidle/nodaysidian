import CoreData
import Foundation

@objc(CanvasEntity)
public class CanvasEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var elementsData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var linkedNoteId: UUID?
}

extension CanvasEntity {
    var displayTitle: String {
        title.isEmpty ? "Untitled Canvas" : title
    }

    var elements: [CanvasElement] {
        get {
            guard let data = elementsData else { return [] }
            return (try? JSONDecoder().decode([CanvasElement].self, from: data)) ?? []
        }
        set {
            elementsData = try? JSONEncoder().encode(newValue)
        }
    }

    var elementCount: Int {
        elements.count
    }

    static func create(
        in context: NSManagedObjectContext,
        title: String = "Untitled Canvas"
    ) -> CanvasEntity {
        let canvas = CanvasEntity(context: context)
        canvas.id = UUID()
        canvas.title = title
        canvas.elementsData = try? JSONEncoder().encode([CanvasElement]())
        canvas.createdAt = Date()
        canvas.modifiedAt = Date()
        return canvas
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CanvasEntity> {
        NSFetchRequest<CanvasEntity>(entityName: "CanvasEntity")
    }

    @nonobjc public class func fetchAll() -> NSFetchRequest<CanvasEntity> {
        let req = fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CanvasEntity.modifiedAt, ascending: false)]
        return req
    }
}
