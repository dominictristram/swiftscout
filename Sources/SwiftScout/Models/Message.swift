import Vapor
import Fluent

final class Message: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Parent(key: "ticket_id")
    var ticket: Ticket
    
    @Parent(key: "user_id")
    var user: User
    
    @OptionalParent(key: "conversation_id")
    var conversation: Conversation?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, content: String, ticketID: UUID, userID: UUID, conversationID: UUID? = nil) {
        self.id = id
        self.content = content
        self.$ticket.id = ticketID
        self.$user.id = userID
        self.$conversation.id = conversationID
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