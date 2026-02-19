import Foundation

enum CanvasElementType: String, Codable, CaseIterable {
    case rect
    case ellipse
    case line
    case arrow
    case text
    case pencil
}

struct CanvasElement: Identifiable, Codable {
    let id: UUID
    var type: CanvasElementType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
    var strokeColor: String    // hex like "2DD4BF"
    var fillColor: String?     // nil = no fill
    var strokeWidth: Double
    var text: String?
    var points: [CodablePoint]?
    var arrowHead: Bool

    init(
        id: UUID = UUID(),
        type: CanvasElementType,
        x: Double = 0,
        y: Double = 0,
        width: Double = 0,
        height: Double = 0,
        rotation: Double = 0,
        strokeColor: String = "EEEEF0",
        fillColor: String? = nil,
        strokeWidth: Double = 2,
        text: String? = nil,
        points: [CodablePoint]? = nil,
        arrowHead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = strokeWidth
        self.text = text
        self.points = points
        self.arrowHead = arrowHead
    }

    var frame: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct CodablePoint: Codable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
