import CoreData
import Foundation

@objc(EdgeEntity)
public class EdgeEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var sourceId: UUID
    @NSManaged public var targetId: UUID
    @NSManaged public var strength: Double
    @NSManaged public var isAutoDiscovered: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var label: String?
}

extension EdgeEntity {
    static func create(
        in context: NSManagedObjectContext,
        sourceId: UUID,
        targetId: UUID,
        strength: Double = 0.5,
        isAuto: Bool = false,
        label: String? = nil
    ) -> EdgeEntity {
        let edge = EdgeEntity(context: context)
        edge.id = UUID()
        edge.sourceId = sourceId
        edge.targetId = targetId
        edge.strength = strength
        edge.isAutoDiscovered = isAuto
        edge.createdAt = Date()
        edge.label = label
        return edge
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EdgeEntity> {
        NSFetchRequest<EdgeEntity>(entityName: "EdgeEntity")
    }
}
