import Vapor
import Fluent

final class Message: Model, Content, Sendable {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Parent(key: "conversation_id")
    var conversation: Conversation
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "ticket_id")
    var ticket: Ticket
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, content: String, conversationId: UUID, userId: UUID, ticketId: UUID) {
        self.id = id
        self.content = content
        self.$conversation.id = conversationId
        self.$user.id = userId
        self.$ticket.id = ticketId
    }
}

extension Message {
    struct Create: Content {
        let content: String
        let ticketID: UUID
    }
}

extension Message.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("content", as: String.self, is: !.empty)
    }
} 