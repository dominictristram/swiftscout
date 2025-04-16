import Vapor
import Fluent

enum ConversationStatus: String, Content {
    case active
    case closed
}

final class Conversation: Model, Content {
    static let schema = "conversations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "ticket_id")
    var ticket: Ticket
    
    @Parent(key: "user_id")
    var user: User
    
    @Children(for: \Message.$conversation)
    var messages: [Message]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, ticketID: UUID, userID: UUID) {
        self.id = id
        self.$ticket.id = ticketID
        self.$user.id = userID
    }
}

enum ConversationType: String, Codable {
    case email
    case note
    case phone
    case chat
}

enum ConversationChannel: String, Codable {
    case email
    case web
    case phone
    case chat
    case api
}

extension Conversation {
    struct Create: Content {
        var ticketID: UUID
        var type: ConversationType
        var channel: ConversationChannel
        var status: ConversationStatus
    }
} 