import Vapor
import Fluent

enum TicketStatus: String, Codable {
    case open
    case inProgress = "in_progress"
    case resolved
    case closed
}

enum TicketPriority: String, Codable {
    case low
    case medium
    case high
    case urgent
}

final class Ticket: Model, Content {
    static let schema = "tickets"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Enum(key: "status")
    var status: TicketStatus
    
    @Enum(key: "priority")
    var priority: TicketPriority
    
    @Parent(key: "created_by_id")
    var createdBy: User
    
    @OptionalParent(key: "assigned_to_id")
    var assignedTo: User?
    
    @Children(for: \.$ticket)
    var messages: [Message]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    var createdByID: UUID? {
        get { $createdBy.id }
        set { $createdBy.id = newValue ?? UUID() }
    }
    
    var assignedToID: UUID? {
        get { $assignedTo.id }
        set { $assignedTo.id = newValue }
    }
    
    init() { }
    
    init(id: UUID? = nil, title: String, description: String, status: TicketStatus = .open, priority: TicketPriority, createdByID: UUID, assignedToID: UUID? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.$createdBy.id = createdByID
        self.$assignedTo.id = assignedToID
    }
}

extension Ticket {
    struct Create: Content {
        var subject: String
        var description: String
        var priority: TicketPriority
        var customerID: UUID
    }
    
    struct Update: Content {
        var title: String?
        var description: String?
        var status: TicketStatus?
        var priority: TicketPriority?
        var assignedToID: UUID?
    }
}

extension Ticket.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("subject", as: String.self, is: .count(1...))
    }
} 